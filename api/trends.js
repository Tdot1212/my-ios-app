module.exports = async (req, res) => {
  res.status(200).json({
    ok: true,
    items: [
      { source: "placeholder", title: "Trends proxy wired up", url: "https://example.com" }
    ]
  });
};
