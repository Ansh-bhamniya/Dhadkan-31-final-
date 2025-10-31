const express = require('express');
const User = require('../models/user');
const PatientDrug = require("../models/PatientDrug");
const responses = require('../utils/responses')
const authMiddleware = require('./authMiddleware');
const mongoose = require('mongoose');

const router = express.Router();

router.get('/', (req, res) => {
    res.json({"all": "good"})
})

router.post('/signup', async (req, res) => {
    let {name, mobile, password, uhid, email, age, gender, doctor_mobile} = req.body;
    if (!name || !mobile || !uhid || !password || !age || !gender || !doctor_mobile) {
        return res.status(400).json(responses.error("Some fields are empty."))
    }

    const existingUser = await User.findOne({mobile: mobile});
    if (existingUser) {
        return res.status(400).json(responses.error("Mobile already exists. Log In."));
    }

    const doctor = await User.findOne({mobile: doctor_mobile, role: "doctor"});
    if (!doctor) {
        return res.status(400).json(responses.error("Such doctor doesn't exist."));
    }

    try {
        const role = "patient";
        age = parseInt(age);
        const user = new User({name, mobile, password, uhid, role, email, age, gender, doctor});
        await user.save();
        res.status(201).json(responses.success("User created successfully. You may log in."));
    } catch {
        res.status(400).json(responses.error("Something went wrong!"))
    }
});

router.post('/add', authMiddleware, async (req, res) => {
    
    const {
    mobile,
    diagnosis,
    otherDiagnosis, 
    weight,
    sbp,
    dbp,
    hr,
    status,
    can_walk,
    can_climb,
    medicines
  } = req.body;

  try {
    
    const patientDrug = new PatientDrug({
      patient: req.user,
      mobile: req.user.mobile,
      diagnosis,
      otherDiagnosis: otherDiagnosis || '', 
      weight: weight ? Number(weight) : undefined,
      sbp: sbp ? Number(sbp) : undefined,
      dbp: dbp ? Number(dbp) : undefined,
      hr: hr ? Number(hr) : undefined,
      status,
      can_walk,
      can_climb,
      medicines: medicines || [],
      created_by: req.user._id
    });

    await patientDrug.save();

    return res.status(201).json(responses.success_data({
      message: "Patient drug data added successfully",
      patientDrug
    }));
  } catch (error) {
    console.warn("Error adding patient drug data:", error);
    return res.status(500).json(responses.error(error.message || "Server error"));
  }

});

router.post('/get-daily-data', authMiddleware, async (req, res) => {
  try {
    const mobile = req.user.mobile;
    const { date } = req.body; // Expect date in YYYY-MM-DD format

    let query = { mobile };
    if (date) {
      // Validate date format
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return res.status(400).json({ success: false, message: "Invalid date format. Use YYYY-MM-DD" });
      }
      // Convert date to start and end of day in UTC
      const startDate = new Date(date);
      startDate.setUTCHours(0, 0, 0, 0);
      const endDate = new Date(date);
      endDate.setUTCHours(23, 59, 59, 999);
      query.created_at = { $gte: startDate, $lte: endDate };
    }

    // Fetch and sort by created_at (descending order = newest first)
    const patientDrugs = await PatientDrug.find(query).sort({ created_at: -1 });

    if (!patientDrugs || patientDrugs.length === 0) {
      return res.status(404).json({ success: false, message: "No records found for this mobile number" });
    }

    res.json({ success: true, data: patientDrugs });
  } catch (error) {
    console.error('Error fetching patient drug data:', error);
    res.status(500).json({ success: false, message: 'Server error', error: error.message });
  }
});

router.post('/validate-token', authMiddleware, (req, res) => {
    res.status(200).json({status: 'valid'});
});

router.delete('/history/:historyId', authMiddleware, async (req, res) => {
    const { historyId } = req.params;
    const userId = req.user._id; 

    if (!mongoose.Types.ObjectId.isValid(historyId)) {
        return res.status(400).json(responses.error("Invalid history ID format."));
    }

    try {
        const historyEntry = await PatientDrug.findById(historyId);
        if (!historyEntry) {
            return res.status(404).json(responses.error("History entry not found."));
        }
        const isPatientOfRecord = historyEntry.patient.equals(userId);

        if (!isPatientOfRecord) {
            return res.status(403).json(responses.error("Unauthorized: You do not have permission to delete this entry."));
        }

        await PatientDrug.findByIdAndDelete(historyId);
        return res.status(200).json(responses.success("History entry deleted successfully.", { deletedId: historyId }));

    } catch (err) {
        console.error("Error deleting patient history entry:", err);
        if (err.kind === 'ObjectId' || err.name === 'CastError') { 
            return res.status(404).json(responses.error("History entry not found or ID is invalid."));
        }
        return res.status(500).json(responses.error("Server error while deleting history entry."));
    }
});

module.exports = router;