/*
 * juration - a natural language duration parser
 * https://github.com/domchristie/juration
 *
 * Copyright 2011, Dom Christie
 * Licenced under the MIT licence
 *
 * stringify was removed.
 * pico->millisecond support has been added
 */

(function() {

  var UNITS = {
    picoseconds: {
      patterns: ['picosecond', 'picosec', 'ps'],
      value: 0.000000000001
    },   
    nanoseconds: {
      patterns: ['nanosecond', 'nanosec', 'ns'],
      value: 0.000000001
    },
    microseconds: {
      patterns: ['microsecond', 'microsec', 'us', 'µs'],
      value: 0.000001
    },
    milliseconds: {
      patterns: ['millisecond', 'millisec', 'ms'],
      value: 0.001
    },
    seconds: {
      patterns: ['second', 'sec', 's'],
      value: 1
    },
    minutes: {
      patterns: ['minute', 'min', 'm(?!s)'],
      value: 60
    },
    hours: {
      patterns: ['hour', 'hr', 'h'],
      value: 3600
    },
    days: {
      patterns: ['day', 'dy', 'd'],
      value: 86400
    },
    weeks: {
      patterns: ['week', 'wk', 'w'],
      value: 604800
    },
    months: {
      patterns: ['month', 'mon', 'mo', 'mth'],
      value: 2628000
    },
    years: {
      patterns: ['year', 'yr', 'y'],
      value: 31536000
    }
  };
  
  var parse = function(string) {
    
    // returns calculated values separated by spaces
    for(var unit in UNITS) {
      for(var i = 0, mLen = UNITS[unit].patterns.length; i < mLen; i++) {
        var regex = new RegExp("((?:\\d+\\.\\d+)|\\d+)\\s?(" + UNITS[unit].patterns[i] + "s?(?=\\s|\\d|\\b))", 'gi');
        string = string.replace(regex, function(str, p1, p2) {
          return " " + (p1 * UNITS[unit].value).toString() + " ";
        });
      }
    }
    
    var sum = 0,
        numbers = string
                    .replace(/(?!\.|e|-)\W+/g, ' ')                       // replaces non-word chars (excluding '.') with whitespace
                    .replace(/^\s+|\s+$|(?:and|plus|with)\s?/g, '')   // trim L/R whitespace, replace known join words with ''
                    .split(' ');
    
    for(var j = 0, nLen = numbers.length; j < nLen; j++) {
      if(numbers[j] && isFinite(numbers[j])) {
         sum += parseFloat(numbers[j]);
      } else if(!numbers[j]) {
        throw "juration.parse(): Unable to parse: a falsey value";
      } else {
        // throw an exception if it's not a valid word/unit
        throw "juration.parse(): Unable to parse: " + numbers[j].replace(/^\d+/g, '');
      }
    }
    return sum;
  };
  
  var juration = {
    parse: parse,
  };

  if ( typeof module === "object" && module && typeof module.exports === "object" ) {
    //loaders that implement the Node module pattern (including browserify)
    module.exports = juration;
  } else {
    // Otherwise expose juration
    window.juration = juration;

    // Register as a named AMD module
    if ( typeof define === "function" && define.amd ) {
      define("juration", [], function () { return juration; } );
    }
  }
})();
