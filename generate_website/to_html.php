<?php

if (count($argv) < 2) {
  echo "Syntax: to_html <document.md>\n";
  exit -1;
}

require ('parsedown/Parsedown.php');

$Parsedown = new Parsedown();
?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>JCodec - </title>
    <style type="text/css" media="all">
      @import url("./css/site.css");
    </style>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>
  <body>
    <div class="wrapper">
      <div class="xright">            <a href="index.html">Home</a>
        <a href="https://github.com/jcodec/jcodec" class="externalLink">Source code</a>
        <a href="https://repo.maven.apache.org/maven2/org/jcodec/">Downloads</a>
    </div>
    <div class="composite">
      <div class="left">
<?php
echo $Parsedown->text(file_get_contents($argv[1]));
?>
      </div>
      <div class="right">
        <img src="./images/jcodec.png" style="margin-top: 20px;"/>
	<!--div class="box">
          <h5>Guides</h5>
          <ul>
            <li class="none">
              <a href="guide/movstitch.html">Stitching h264 movies</a>
            </li>
            <li class="none">
              <a href="guide/avcmp4mux.html">Muxing h264 (avc) into mp4</a>
            </li>
          </ul>
          <h5>H264</h5>
          <ul>
            <li class="none">
              <a href="h264/index.html">Index</a>
            </li>
          </ul>
        </div-->
      </div>
    </div>
    <!--div class="links"><a href="./contrib.html">Contributors</a>&nbsp;|&nbsp;<a href="./lic.html">Licence</a></div>
    </div-->
  </body>
  <script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-67032028-1', 'auto');
    ga('send', 'pageview');

  </script>
</html>
