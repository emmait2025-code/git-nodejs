const express = require("express");
const app = express();
const port = 8080;

app.get("/", (req, res)  => {
 res.send("<h3>Bjr depuis OShift GitHub direct</h3>");
});

app.listen(port, () => console.log('App running on port ${port}'));

