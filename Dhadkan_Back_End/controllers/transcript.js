// controller/transcript.js
const express = require('express');
const axios = require('axios');
const multer = require('multer'); // for handling file upload
const fs = require('fs');
const router = express.Router();

// setup multer (stores file locally)
const upload = multer({ dest: 'uploads/' });

// AssemblyAI API Key (put it in .env)
const ASSEMBLYAI_API_KEY = process.env.ASSEMBLYAI_API_KEY;

// Upload + Transcribe route
router.post('/transcribe', upload.single('audio'), async (req, res) => {
  console.log(">>>>");
  try {
    if (!req.file) return res.status(400).json({ error: 'No audio file uploaded' });

    // Step 1: Upload audio to AssemblyAI
    const fileStream = fs.createReadStream(req.file.path);

    const uploadRes = await axios.post(
      'https://api.assemblyai.com/v2/upload',
      fileStream,
      {
        headers: {
          authorization: ASSEMBLYAI_API_KEY,
          'transfer-encoding': 'chunked',
        },
      }
    );

    const audioUrl = uploadRes.data.upload_url;

    // Step 2: Request transcription
    const transcriptRes = await axios.post(
      'https://api.assemblyai.com/v2/transcript',
      { audio_url: audioUrl },
      {
        headers: {
          authorization: ASSEMBLYAI_API_KEY,
          'content-type': 'application/json',
        },
      }
    );

    const transcriptId = transcriptRes.data.id;

    // Step 3: Poll for result
    let transcript;
    while (true) {
      const pollingRes = await axios.get(
        `https://api.assemblyai.com/v2/transcript/${transcriptId}`,
        { headers: { authorization: ASSEMBLYAI_API_KEY } }
      );

      transcript = pollingRes.data;

      if (transcript.status === 'completed') break;
      if (transcript.status === 'error') throw new Error(transcript.error);

      // wait 3 sec before next poll
      // await new Promise((r) => setTimeout(r, 3000));
    }

    // Send back transcription text
    res.json({ text: transcript.text.replace(/\./g,'')});

    // cleanup temp file
    fs.unlinkSync(req.file.path);

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Transcription failed' });
  }
});

module.exports = router;
