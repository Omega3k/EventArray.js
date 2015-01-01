(function() {
  module.exports = function(grunt) {
    var license, pkg, _;
    _ = grunt.util._;
    pkg = grunt.file.readJSON("package.json");
    license = grunt.file.read("LICENSE");
    grunt.initConfig({
      pkg: pkg,
      watch: {
        EventArray: {
          files: ["src/EventArray.coffee"],
          tasks: ["build"]
        },
        Gruntfile: {
          files: ["src/Gruntfile.coffee"],
          tasks: ["coffee:Gruntfile", "jshint:Gruntfile"]
        },
        frontEnd: {
          files: ["src/ux.coffee"],
          tasks: ["coffee:frontEnd", "jshint:frontEnd"]
        }
      },
      coffee: {
        EventArray: {
          options: {
            join: true,
            sourceMap: true
          },
          files: {
            "build/EventArray.min.js": ["src/EventArray.coffee"]
          }
        },
        Gruntfile: {
          files: {
            "Gruntfile.js": ["src/Gruntfile.coffee"]
          }
        },
        frontEnd: {
          files: {
            "src/ux.js": ["src/ux.coffee"]
          }
        }
      },
      jshint: {
        options: {
          eqeqeq: true,
          eqnull: true,
          node: true,
          undef: true,
          globals: {
            "window": true,
            module: true,
            exports: true,
            require: true,
            define: true
          }
        },
        EventArray: ["build/EventArray.min.js"],
        Gruntfile: ["Gruntfile.js"],
        frontEnd: ["src/ux.js"]
      },
      uglify: {
        options: {
          banner: "/*\n" + license + "*/\n\n"
        },
        EventArray: {
          files: {
            "build/EventArray.min.js": ["build/EventArray.min.js"]
          }
        }
      }
    });
    _.map(pkg.devDependencies, function(val, key) {
      if (key !== "grunt" && key.indexOf("grunt") === 0) {
        return grunt.loadNpmTasks(key);
      }
    });
    grunt.registerTask("default", "dev");
    grunt.registerTask("dev", ["build", "watch"]);
    return grunt.registerTask("build", ["coffee", "jshint", "uglify"]);
  };

}).call(this);
