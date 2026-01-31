// This script runs automatically on first container start
// Creates the application database and user
// Reads credentials from environment variables passed by docker-compose

const appUser = process.env.MONGO_APP_USER || 'cam_user';
const appPassword = process.env.MONGO_APP_PASSWORD || 'cam_dev_password';
const appDatabase = process.env.MONGO_APP_DATABASE || 'class_activity_manager';

db = db.getSiblingDB(appDatabase);

db.createUser({
  user: appUser,
  pwd: appPassword,
  roles: [
    { role: 'readWrite', db: appDatabase }
  ]
});

print('Created user ' + appUser + ' for ' + appDatabase + ' database');
