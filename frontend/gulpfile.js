var gulp = require('gulp'),
   concat = require('gulp-concat'),
   jshint = require('gulp-jshint'),
   // sourcemaps = require('gulp-sourcemaps'),
   uglify = require('gulp-uglify');

gulp.task('watch', function() {
  gulp.src(['js/app.model.js','js/app.controller.js', 'js/app.view.js'])
        .pipe(jshint())
        .pipe(jshint.reporter('default'))
        .pipe(concat('app.js'))
        // .pipe(sourcemaps.init())
        .pipe(uglify())
        // .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest('../static'));
    gulp.watch('js/app.*.js', ['js']);
});

gulp.task('js', function () {
   gulp.src(['js/app.model.js','js/app.controller.js', 'js/app.view.js'])
        .pipe(jshint())
        .pipe(jshint.reporter('default'))
        .pipe(concat('app.js'))
        // .pipe(sourcemaps.init())
        .pipe(uglify())
        // .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest('../static'))
});