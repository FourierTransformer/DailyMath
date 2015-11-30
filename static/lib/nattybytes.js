/*
 * nattybytes - a natural language digital storage parser
 * https://github.com/FourierTransformer/nattybytes
 *
 * Copyright 2015, Shakil Thakur
 * Licenced under the MIT licence
 *
 * Heavily based on Dom Christie's Juration
 *
 */

(function() {
    var UNITS = {
        bit: {
            patterns: ['bit'],
            value: 1
        },

        byte: {
            patterns: ['byte'],
            value: 8
        }

    }

    // exception to prefixes is binary prefix kibi is "K"
    var prefixes = ['K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']
    var decimalPrefixes = ['kilo', 'mega', 'giga', 'tera', 'peta', 'exa'] //, 'zetta', 'yotta']

    // can't handle them big ones...
    var binaryPrefixes = ['kibi', 'mebi', 'gibi', 'tebi', 'pebi', 'exbi'] //, 'zebi', 'yobi']

    var suffixes = {
        bit: {
            multiplier: 1
        },

        byte: {
            multiplier: 8
        }
    }

    decimalPrefixes.map(function(prefix, index) {
        for (var suffix in suffixes) {
            if (suffixes.hasOwnProperty(suffix)) {
                var name = prefix + suffix;
                var patternsToAdd = [name];

                if (suffix === 'bit') {
                    patternsToAdd.push(prefixes[index] + 'b')
                    patternsToAdd.push(prefixes[index] + 'bit')
                } else {
                    if (prefix === 'kilo') {
                        patternsToAdd.push('kB')
                    }
                    patternsToAdd.push(prefixes[index] + 'B')
                    patternsToAdd.push(prefixes[index])
                }

                UNITS[name] = {
                    value: Math.pow(1000, index+1) * suffixes[suffix].multiplier,
                    patterns: patternsToAdd
                }
            }
        }
    })

    binaryPrefixes.map(function(prefix, index) {
        for (var suffix in suffixes) {
            if (suffixes.hasOwnProperty(suffix)) {
                var name = prefix + suffix;
                var patternsToAdd = [name];

                if (suffix === 'bit') {
                    patternsToAdd.push(prefixes[index] + 'ibit')
                } else {
                    patternsToAdd.push(prefixes[index] + 'iB')
                }

                UNITS[name] = {
                    value: Math.pow(1000, index+1) * suffixes[suffix].multiplier,
                    patterns: patternsToAdd
                }
            }
        }
    })

var parse = function(string) {
    
    // returns calculated values separated by spaces
    for(var unit in UNITS) {
      for(var i = 0, mLen = UNITS[unit].patterns.length; i < mLen; i++) {
        var regex;
        if (i === 0) {
            regex = new RegExp("((?:\\d+\\.\\d+)|\\d+)\\s?(" + UNITS[unit].patterns[i] + "s?(?=\\s|\\d|\\b))", 'gi');
        } else {
            regex = new RegExp("((?:\\d+\\.\\d+)|\\d+)\\s?(" + UNITS[unit].patterns[i] + "s?(?=\\s|\\d|\\b))", 'g');
        }

        string = string.replace(regex, function(str, p1, p2) {
          return " " + (p1 * UNITS[unit].value).toString() + " ";
        });
      }
    }
    
    var sum = 0,
        numbers = string
                    .replace(/(?!\.)\W+/g, ' ')                       // replaces non-word chars (excluding '.') with whitespace
                    .replace(/^\s+|\s+$|(?:and|plus|with)\s?/g, '')   // trim L/R whitespace, replace known join words with ''
                    .split(' ');
    
    for(var j = 0, nLen = numbers.length; j < nLen; j++) {
      if(numbers[j] && isFinite(numbers[j])) {
         sum += parseFloat(numbers[j]);
      } else if(!numbers[j]) {
        throw "nattybytes.parse(): Unable to parse: a falsey value";
      } else {
        // throw an exception if it's not a valid word/unit
        throw "nattybytes.parse(): Unable to parse: " + numbers[j].replace(/^\d+/g, '');
      }
    }
    return sum;
  };
  
  var nattybytes = {
    parse: parse,
  };

  if ( typeof module === "object" && module && typeof module.exports === "object" ) {
    //loaders that implement the Node module pattern (including browserify)
    module.exports = nattybytes;
  } else {
    // Otherwise expose nattybytes
    window.nattybytes = nattybytes;

    // Register as a named AMD module
    if ( typeof define === "function" && define.amd ) {
      define("nattybytes", [], function () { return nattybytes; } );
    }
  }

})();