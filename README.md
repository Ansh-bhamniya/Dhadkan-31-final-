### Dhadkan

A full-stack project with a Node.js/Express backend and a Flutter frontend.

### Project structure

- `Dhadkan_Back_End`: Node.js/Express API (MongoDB, JWT, file uploads, websockets)
- `Dhadkan_Front_End`: Flutter application (Android, iOS, Web, Desktop)

### Prerequisites

- **Backend**: Node.js 18+, npm, MongoDB URI, Cloudinary credentials (if using uploads)
- **Frontend**: Flutter SDK, Android Studio/Xcode as needed

### Backend setup

1) Move to backend directory

```bash
cd Dhadkan_Back_End
```

2) Install dependencies

```bash
npm install
```

3) Configure environment variables (create a `.env` file)

```bash
PORT=5000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

4) Start the server

```bash
npm start
```

The server entrypoint is `index.js` and runs on `PORT` (default 5000).

### Frontend setup

1) Move to frontend directory

```bash
cd Dhadkan_Front_End
```

2) Get Flutter dependencies

```bash
flutter pub get
```

3) Run the app

```bash
flutter run
```

To build for Android/iOS/Desktop/Web, use standard Flutter build commands
such as `flutter build apk`, `flutter build ios`, etc.

### Notes

- The frontend README at `Dhadkan_Front_End/README.md` contains Flutter references and links.
- Ensure the frontend is configured to point to the backend base URL where required.

