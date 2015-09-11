// module StaticMiddleware
var express = require('express');
exports.publicMiddleware = express.static('public');
exports.bowerMiddleware = express.static('bower_components');
