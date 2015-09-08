// --- gulpfile.js : le fichier complet ---

var gulp      = require('gulp'),
    minifyCss = require('gulp-minify-css'),
    uglify    = require('gulp-uglify'),
    plumber   = require('gulp-plumber');
    minifyHTML = require('gulp-minify-html');

gulp.task('minify-html', function() {

  return gulp.src('./dev/pages/*.page')
    .pipe(plumber())
    .pipe(minifyHTML())
    .pipe(gulp.dest('./src/pages'));
});


// SCSS TASK
gulp.task('css', function()
{
  return gulp.src('./dev/staticresources/deploymentcss.resource')
    .pipe(plumber())
    .pipe(minifyCss())
    .pipe(gulp.dest('./src/staticresources/'));
});


// JAVASCRIPT TASK
gulp.task('js-uglify', function()
{
  return gulp.src('./dev/staticresources/deploymentjs.resource')
    .pipe(plumber())
    .pipe(uglify())
    .pipe(gulp.dest('./src/staticresources/'));
});


// WATCH TASK
gulp.task('watch', function()
{
  gulp.watch('./dev/staticresources/deploymentcss.resource', ['css']);
  gulp.watch('./dev/staticresources/deploymentjs.resource', ['js-uglify']);
  gulp.watch('./dev/pages/*.page', ['minify-html']);
});


gulp.task('default', ['watch']);