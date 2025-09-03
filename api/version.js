module.exports = (req, res) => {
  res.status(200).json({
    sha: process.env.VERCEL_GIT_COMMIT_SHA || null,
    time: new Date().toISOString()
  });
};
