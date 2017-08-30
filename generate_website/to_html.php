<?php

if (count($argv) < 2) {
  echo "Syntax: to_html <document.md>\n";
  exit -1;
}

require ('parsedown/Parsedown.php');

$sameLevel = array();
if (count($argv > 2)) {
    $sameLevel = array_diff(explode(",", $argv[2]), array("README.md"));
}
array_push($sameLevel, "LICENSE");

$docsLevel = array();
if (count($argv > 3)) {
    $docsLevel = explode(",", $argv[3]);
}

$Parsedown = new Parsedown();
?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>JCodec - </title>
    <style type="text/css" media="all">
      @import url("/css/site.css");
    </style>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>
  <body>
    <div class="wrapper">
      <div class="xright">            <a href="/index.html">Home</a>
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
        <img src="/images/jcodec.png" style="margin-top: 20px;"/>
<?php
    $numItems = count($docsLevel);
    if ($numItems > 0) {
?>
        <div class="box">
          <h5>Topics</h5>
          <ul>
<?php
      foreach($docsLevel as $page) {
        $path_parts = pathinfo($page);
?>
            <li class="none">
              <a href="docs/<?= $path_parts['filename'] ?>.html"><?= ucfirst(str_replace('_', ' ', strtolower($path_parts['filename']))) ?></a>
            </li>
<?php
      }
?>
          </ul>
        </div>
<?php 
    }
?>
      </div>
    </div>
<?php
    $numItems = count($sameLevel);
    if ($numItems > 0) {
?>
    <div class="links">
<?php
      $i = 0;
      foreach($sameLevel as $page) {
        $path_parts = pathinfo($page);
?>
      <a href="<?= $path_parts['filename'] ?>.html"><?= ucfirst(strtolower($path_parts['filename'])) ?></a>
<?php
        if ($i < $numItems - 1) { 
?>
      	&nbsp;|&nbsp;
<?php 
        }
        $i++;
      }
?>
    	</div>
<?php
    }
?>
    </div>
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
