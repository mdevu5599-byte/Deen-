/** Static export so the dashboard can be served from Firebase Hosting.
 *  All data access happens client-side against Firestore (rules enforce roles)
 *  and through callable Cloud Functions (server-side role checks). */
module.exports = {
  output: 'export',
  images: {unoptimized: true},
  eslint: {ignoreDuringBuilds: true},
};
