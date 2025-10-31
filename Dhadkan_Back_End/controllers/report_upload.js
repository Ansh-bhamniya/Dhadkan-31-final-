const express = require('express');
const router = express.Router();
const multer = require('multer');
const { storage, fileFilter, ALLOWED_IMAGE_TYPES, ALLOWED_PDF_TYPE } = require('../config/cloudinary');
const Report = require('../models/Report');
const authMiddleware = require('./authMiddleware'); 
const moment = require('moment-timezone');


const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024,
  }
});

const multiUpload = upload.fields([
  { name: 'opd_card', maxCount: 1 },
  { name: 'echo', maxCount: 1 },
  { name: 'ecg', maxCount: 1 },
  { name: 'cardiac_mri', maxCount: 1 },
  { name: 'bnp', maxCount: 1 },
  { name: 'biopsy', maxCount: 1 },
  { name: 'biochemistry_report', maxCount: 1 }
]);

const isImage = (mimetype) => ALLOWED_IMAGE_TYPES.includes(mimetype);
const isPDF = (mimetype) => mimetype === ALLOWED_PDF_TYPE;

router.post('/upload/:patientId', authMiddleware, (req, res) => {
  multiUpload(req, res, async (err) => {
    if (err) {
      console.error('Multer error during file upload:', err);
      return res.status(400).json({
        success: false,
        error: err.message || 'File upload failed',
        allowedTypes: [...ALLOWED_IMAGE_TYPES, ALLOWED_PDF_TYPE]
      });
    }

    try {
      const fields = Object.keys(req.files || {});
      const reportData = {};
      const comments = req.body || {};

      // Get the current time in IST as a Date object
      const nowIST = moment().tz('Asia/Kolkata').toDate();

      for (const field of fields) {
        const files = req.files[field];
        if (!files || files.length === 0) continue;

        const file = files[0];

        if (!isImage(file.mimetype) && !isPDF(file.mimetype)) {
          throw new Error(`Invalid file type for ${field}: ${file.mimetype}. Allowed types are images and PDFs.`);
        }

        reportData[field] = {
          path: file.path,
          url: file.url || file.path,
          type: isPDF(file.mimetype) ? 'pdf' : 'image',
          originalname: file.originalname,
          size: file.size,
          comment: comments[field] || null,
          uploadedAt: nowIST, // Store IST as a Date object
        };
      }

      if (Object.keys(reportData).length === 0) {
        return res.status(400).json({
          success: false,
          error: 'No valid files uploaded or processed.'
        });
      }

      const report = new Report({
        patient: req.params.patientId,
        mobile: req.user.mobile,
        time: nowIST, // Use IST for the main report time as well
        files: reportData
      });

      await report.save();

      const responseData = {
        success: true,
        message: 'Files uploaded and report created successfully!',
        report: {
          _id: report._id,
          patient: report.patient,
          mobile: report.mobile,
          time: report.time,
          timeIST: moment(report.time).tz('Asia/Kolkata').format('YYYY-MM-DD HH:mm:ss'),
          files: Object.fromEntries(
            Object.entries(report.files).map(([key, file]) => {
              // uploadedAt is now already in IST, so we just format it
              const uploadedAtIST = file?.uploadedAt
                ? moment(file.uploadedAt).tz('Asia/Kolkata').format('YYYY-MM-DD HH:mm:ss')
                : null;

              return [
                key,
                {
                  ...file,
                  uploadedAtIST // This will now be the formatted IST string
                }
              ];
            })
          ),
          createdAt: report.createdAt,
          updatedAt: report.updatedAt
        },
        reportId: report._id,
        uploadedFiles: Object.keys(reportData)
      };

      res.status(201).json(responseData);

    } catch (err) {
      console.error('Error creating report after file upload:', err);
      res.status(500).json({
        success: false,
        error: 'Failed to create report',
        details: err.message
      });
    }
  });
});

router.get('/:patientId', authMiddleware, async (req, res) => {
  try {
    const reports = await Report.find({ patient: req.params.patientId })
      .sort({ time: -1 })
      .lean();

    if (!reports || reports.length === 0) {
      return res.status(404).json({ message: 'No reports found for this patient.' });
    }

    const latestReport = reports[0];

    const consolidatedFiles = {};
    const reportTypes = ['opd_card', 'echo', 'ecg', 'cardiac_mri', 'bnp', 'biopsy', 'biochemistry_report'];

    reportTypes.forEach(type => {
      for (const report of reports) {
        if (report.files && report.files[type]) {
          // Calculate uploadedAtIST for the GET response
          const uploadedAtIST = report.files[type].uploadedAt
            ? moment(report.files[type].uploadedAt).tz('Asia/Kolkata').format('YYYY-MM-DD HH:mm:ss')
            : null;

          consolidatedFiles[type] = {
            ...report.files[type],
            reportTime: report.time,
            reportId: report._id,
            uploadedAtIST: uploadedAtIST // Add the formatted IST string
          };
          break;
        }
      }
    });

    const response = {
      _id: latestReport._id,
      patient: latestReport.patient,
      mobile: latestReport.mobile,
      time: latestReport.time,
      files: consolidatedFiles,
      hasReports: Object.keys(consolidatedFiles).length > 0
    };

    res.status(200).json({ report: response });
  } catch (err) {
    console.error('Error fetching consolidated reports:', err);
    res.status(500).json({ error: 'Failed to fetch reports.' });
  }
});

router.get('/report/:reportId', authMiddleware, async (req, res) => {
  try {
    const report = await Report.findById(req.params.reportId);
    if (!report) {
      return res.status(404).json({ message: 'Report not found.' });
    }
    res.status(200).json(report);
  } catch (err) {
    console.error('Error fetching single report:', err);
    res.status(500).json({ error: 'Failed to fetch report.' });
  }
});


router.get('/:patientId', authMiddleware, async (req, res) => {
  try {
    const reports = await Report.find({ patient: req.params.patientId })
      .sort({ time: -1 })
      .lean(); 

    if (!reports || reports.length === 0) {
      return res.status(404).json({ message: 'No reports found for this patient.' });
    }

    const latestReport = reports[0]; 
    
    const consolidatedFiles = {}; 
    const reportTypes = ['opd_card', 'echo', 'ecg', 'cardiac_mri', 'bnp', 'biopsy', 'biochemistry_report'];
    
    reportTypes.forEach(type => {
      for (const report of reports) {
        if (report.files && report.files[type]) {
          consolidatedFiles[type] = {
            ...report.files[type],
            reportTime: report.time,
            reportId: report._id 
          };
          break;
        }
      }
    });

    const response = {
      _id: latestReport._id, 
      patient: latestReport.patient,
      mobile: latestReport.mobile,
      time: latestReport.time,
      files: consolidatedFiles, 
      hasReports: Object.keys(consolidatedFiles).length > 0
    };

    res.status(200).json({ report: response });
  } catch (err) {
    console.error('Error fetching consolidated reports:', err);
    res.status(500).json({ error: 'Failed to fetch reports.' });
  }
});

router.get('/report/:reportId', authMiddleware, async (req, res) => {
  try {
    const report = await Report.findById(req.params.reportId);
    if (!report) {
      return res.status(404).json({ message: 'Report not found.' });
    }
    res.status(200).json(report);
  } catch (err) {
    console.error('Error fetching single report:', err);
    res.status(500).json({ error: 'Failed to fetch report.' });
  }
});

module.exports = router;
