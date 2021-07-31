<html>
<head>
  <!-- <title>Fix SRT files that are out of sync</title> -->
</head>
<body>
<h1>Fix SRT files that are out of sync</h1>
<p>
Media players often read movie subtitles from .srt files that are found in the same folder as the movie file.
Sometimes these subtitles have incorrect timing because they were originally created for a version of the movie that ran at a slightly different speed. For example, if the subtitle timestamps match a version of the movie that ran at 24 fps, then if the movie is viewed at 23.976 fps, the subtitles will be displayed about 3-7 seconds too early during the second hour of a two-hour movie. Or if the same movie is viewed at 25 fps, the subtitles will instead be displayed several minutes too late.
</p>

<p>
This script can fix this by applying what is sometimes called an affine transformation t' = At + B to every timestamp t in the .srt file. Invoke the script with the --help option for more details.
</p>

<p>
Of course another solution is to adjust the framerate of the movie file instead, but that takes more work.
</p>

</body>
</html>
