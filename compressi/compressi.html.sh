cat <<XXX
<html>
<head>
<style>
  table {
    border-collapse: collapse;
  }

  table, th, td {
    border: 1px solid black;
  }
  
  td {
    padding: 3px;
  }
  
  td.percent {
    text-align: right;
  }
  tr.header {
    background-color: lightgrey;
  }
  tr.selected {
    background-color: #88aaaa;
  }
  tr.bottomline {
    font-weight: bold;
  }
  body {
    font-family: "Lucida Console", Monaco, monospace;
  }
  td.name {
    cursor: grab;
  }
  #box-shadow-div{
    position: fixed;
    width: 200px;
    height: 200px;
    border: 1px solid black;
    background-color: #ffffff;
    display: none;
  }
  #graph {
    cursor: crosshair;
  }
</style>
<script>
var groupBy = function(xs, key) {
  return xs.reduce(function(rv, x) {
    (rv[x[key]] = rv[x[key]] || []).push(x);
    return rv;
  }, {});
};

function rnd1d(val) {
  return Math.round(val*10)/10;
}

function fmtNum(x) {
  return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function Smoother() {
  var ret = {
    prev: [],
    num: 0,
    smooth: function (val) {
      var sum = 0;
      for (var i = 0; i < this.prev.length - 1; i++) {
        this.prev[i] = this.prev[i + 1];
        sum         += this.prev[i];
      }
      sum += val;
      this.prev[this.prev.length - 1] = val;
      this.num = this.num < this.prev.length ? this.num + 1 : this.num;

      return sum / this.num;
    }
  };

  for (var i = 0; i < 8; i++) ret.prev[i] = 0;

  return ret;
}
</script>
<script>
  var PADDING=0.05;
  var SCALE=8;
  var VIEWOFF=30;
  var MARGIN=20;

  var prevSelected;
  var curData1;
  var curData2;

  function bind1(data1, data2, el) {
     el.onclick = function() {
       el.className='selected';
       if (prevSelected)
         prevSelected.className='';
       prevSelected = el;
       plot2(data1, data2);
       curData1 = data1;
       curData2 = data2;
     }
  }

  function findBot(data, value) {
    return data.reduce(function(p, c) {
        return c.psnr1 < value && (!p || c.psnr1 > p.psnr1) ? c : p;
      }, null);
  }
  function findTop(data, value) {
    return data.reduce(function(p, c) {
        return c.psnr1 > value && (!p || c.psnr1 < p.psnr1) ? c : p;
      }, null);
  }

  function interp(data) {
    var interp = [];
    for (var i = 0; i < 60; i++) {
      var bot = findBot(data, i);
      var top = findTop(data, i);
      if (bot && top) {
        var botBps  = parseFloat(bot.bps);
        var botPsnr = parseFloat(bot.psnr1);
        var topBps  = parseFloat(top.bps);
        var topPsnr = parseFloat(top.psnr1);

        interp[i] = botBps + ((i - botPsnr) * (topBps - botBps) / (topPsnr - botPsnr));
      }
    }
    return interp;
  }

  function calcSeparation(data1, data2) {
     var interp1 = interp(data1);
     var interp2 = interp(data2);
     var sum = 0;
     var count = 0;
     for (var i = 0; i < 60; i++) {
        if (interp1[i] && interp2[i]) {
          var a = interp1[i];
          var b = interp2[i];
          var min = a < b ? a : b;
          var max = a > b ? a : b;
          var diff = (max / min) - 1;
          diff *= (a == max ? 1 : -1);
          sum += diff;
          count ++;
        }
     }
     return 100*sum/count;
  }

  function findRanges(data) {
    var r = {mnPsnr: null, mxPsnr: null, mnBps: null, mxBps: null};
    data.forEach(function(e) {
      var psnr = parseFloat(e.psnr1);
      var bps  = parseFloat(e.bps);
      if (!r.mnPsnr || psnr < r.mnPsnr)
        r.mnPsnr = psnr;
      if (!r.mxPsnr || psnr > r.mxPsnr)
        r.mxPsnr = psnr;
      if (!r.mnBps  || bps  < r.mnBps)
        r.mnBps = bps;
      if (!r.mxBps  || bps  > r.mxBps)
        r.mxBps = bps;
    });
    return r;
  }

  function findMaxRanges(data1, data2) {
    var r1 = findRanges(data1);
    var r2 = findRanges(data2);
    var r = {
      mnPsnr: Math.min(r1.mnPsnr, r2.mnPsnr), 
      mxPsnr: Math.max(r1.mxPsnr, r2.mxPsnr), 
      mnBps: Math.min(r1.mnBps, r2.mnBps), 
      mxBps: Math.max(r1.mxBps, r2.mxBps)};
    return r;
  }


  function plot2(data1, data2) {
    var graph = document.getElementById('graph');
    var ctx = graph.getContext("2d");
    ctx.clearRect(0, 0, graph.width, graph.height);

    var r = findMaxRanges(data1, data2);

    ctx.font = "14px Arial";
    ctx.fillText(fmtNum(r.mnPsnr) + 'db / ' + fmtNum(r.mnBps) + 'bps', 0, graph.height - 10);
    ctx.fillText(fmtNum(r.mxBps)  + 'bps', graph.width - 100, graph.height - 10);
    ctx.fillText(fmtNum(r.mxPsnr) + 'db', 0, 20);

    plotPoints(graph, ctx, data1, r, '#ffaaaa');
    plotPoints(graph, ctx, data2, r, '#aaaaff');
  }

  function plotPoints(graph, ctx, data, r, color) {
    var lft   = PADDING     * graph.width;
    var right = (1-PADDING) * graph.width;
    var top   = PADDING     * graph.height;
    var bottm = (1-PADDING) * graph.height;
    var wdt   = right - lft;
    var hgt   = bottm - top;

    data.sort(function(a,b) {
      return a.bps - b.bps;
    });

    var rx = wdt / (r.mxBps  - r.mnBps);
    var ry = hgt / (r.mxPsnr - r.mnPsnr);

    ctx.strokeStyle = '#eeeeee'
    data.forEach(function(item, idx) {
      var x = lft    + (item.bps   - r.mnBps)  * rx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, graph.height);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(graph.width, y);
      ctx.stroke();
    });

    ctx.strokeStyle = color;
    ctx.beginPath();
    data.forEach(function(item, idx) {
      var x = lft    + (item.bps   - r.mnBps)  * rx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      if (idx == 0)
        ctx.moveTo(x, y);
      else
        ctx.lineTo(x, y);
    });
    ctx.stroke();

    data.forEach(function(item) {
      var x = lft    + (item.bps   - r.mnBps)  * rx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      ctx.beginPath();
      ctx.arc(x, y, 2, 0, 2 * Math.PI);
      ctx.stroke();
    });
  }

  function plotZoom(cx, cy) {
    var r = findMaxRanges(curData1, curData2);

    var graph = document.getElementById('small_graph');
    var ctx = graph.getContext("2d");
    ctx.clearRect(0, 0, graph.width, graph.height);

    plotZoomData(ctx, curData1, cx, cy, 0, r, '#ffaaaa');
    plotZoomData(ctx, curData2, cx, cy, 1, r, '#aaaaff');

    ctx.beginPath();
    ctx.strokeStyle = '#888888'
    ctx.moveTo(graph.width/2, 0);
    ctx.lineTo(graph.width/2, graph.height - 30);
    ctx.moveTo(0, graph.height/2);
    ctx.lineTo(graph.width, graph.height/2);
    ctx.stroke();
  }

  function plotZoomData(ctx, data, cx, cy, ind, r, color) {
    var big   = document.getElementById('graph');
    var graph = document.getElementById('small_graph');

    var lft   = PADDING    * big.width;
    var right = (1-PADDING)* big.width;
    var top   = PADDING    * big.height;
    var bottm = (1-PADDING) *big.height;
    var wdt   = right - lft;
    var hgt   = bottm - top;

    var offx = graph.width /2;
    var offy = graph.height/2;

    data.sort(function(a,b) {
      return a.bps - b.bps;
    });

    var rx = wdt / (r.mxBps  - r.mnBps);
    var ry = hgt / (r.mxPsnr - r.mnPsnr);

    ctx.strokeStyle = '#eeeeee'
    data.forEach(function(item, idx) {
      var x = lft   + (item.bps   - r.mnBps)  * rx;
      var sx = SCALE*(x-cx)+offx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      var sy = SCALE*(y-cy)+offy;
      ctx.beginPath();
      ctx.moveTo(sx, 0);
      ctx.lineTo(sx, graph.height);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, sy);
      ctx.lineTo(graph.width, sy);
      ctx.stroke();
    });

    ctx.strokeStyle = color;
    ctx.beginPath();
    data.forEach(function(item, idx) {
      var x = lft   + (item.bps   - r.mnBps)  * rx;
      var sx = SCALE*(x-cx)+offx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      var sy = SCALE*(y-cy)+offy;
      if (idx == 0)
        ctx.moveTo(sx, sy);
      else
        ctx.lineTo(sx, sy);
    });
    ctx.stroke();
    data.forEach(function(item) {
      var x = lft   + (item.bps   - r.mnBps)  * rx;
      var y = bottm - (item.psnr1 - r.mnPsnr) * ry;
      ctx.beginPath();
      ctx.arc(SCALE*(x-cx)+offx, SCALE*(y-cy)+offy, 4, 0, 2 * Math.PI);
      ctx.stroke();
    });

    var cbps  = Math.round((cx - lft)   / rx + r.mnBps);
    var cpsnr = rnd1d     ((bottm - cy) / ry + r.mnPsnr);

    if (ind == 0) {
      ctx.font = "14px Arial";
      ctx.fillText(fmtNum(cpsnr) + 'db', 10, graph.height - 10);
      ctx.fillText(fmtNum(cbps) + 'bps', graph.width/2, graph.height - 10);
    }
  }

  function root() {
    var data1 = JSON.parse(dataset1);
    var data2 = JSON.parse(dataset2);
    var content = document.getElementById('content');
    var byFileName1 = groupBy(data1.points, 'filename');
    var byFileName2 = groupBy(data2.points, 'filename');
    var str = '';
    str += '<div>Profile: ' + data1.profile + '</div>';
    str += '<div>Frames: ' + data1.maxFrames + '</div>';
    str += '<table>';
    str += '<tr class="header"><td>Stream</td><td><span style="color: #ffaaaa;">A</span> vs <span style="color: #aaaaff;">B</span>%</td></tr>';
    var sum = 0;
    var count = 0;
    for (key in byFileName1) {
      if (key == 'DUMMY')
        continue;
      var diff = calcSeparation(byFileName1[key], byFileName2[key]);
      sum   += diff;
      count += 1;
      str += '<tr id="clk_' + key + '"><td class="name">' + key + '</td><td class="percent">' + (Math.round(diff*100)/100)  + '%</td></tr>';
    }
    if (count != 0)
      str += '<tr class="bottomline"><td>Average</td><td class="percent">' + (Math.round((sum/count)*100)/100)  + '%</td></tr>';
    str += '</table>';

    str += '<div style="color: #ffaaaa;">A: ' + data1.encoder + data1.extraArgs + '</div>';
    str += '<div style="color: #aaaaff;">B: ' + data2.encoder + data2.extraArgs + '</div>';
    content.innerHTML = str;
    count = 0;
    for (key in byFileName1) {
       var el = document.getElementById('clk_' + key);
       if (el) {
         bind1(byFileName1[key], byFileName2[key], el);
         if (!count) el.onclick();
         ++count;
       }
    }
  
    var bsDiv = document.getElementById("box-shadow-div");
    var graph = document.getElementById('graph');
    var smx = new Smoother();
    var smy = new Smoother();
    graph.addEventListener('mousemove', function(event){
      if (!curData1 || !curData2)
        return;
      var x = event.clientX;
      var y = event.clientY;
      if ( typeof x !== 'undefined' ){

        var dy = smy.smooth(y);
        if (dy + VIEWOFF + bsDiv.offsetHeight >= window.innerHeight - MARGIN) {
          bsDiv.style.top = (window.innerHeight - MARGIN - bsDiv.offsetHeight) + "px";
        } else {
          bsDiv.style.top = (dy + VIEWOFF) + "px";
        }

        var dx = smx.smooth(x);
        if (dx + VIEWOFF + bsDiv.offsetWidth >= window.innerWidth - MARGIN) {
          bsDiv.style.left = (window.innerWidth - MARGIN - bsDiv.offsetWidth) + "px";
        } else {
          bsDiv.style.left = (dx + VIEWOFF) + "px";
        }
      }
      plotZoom(x - graph.offsetLeft + document.body.scrollLeft, y - graph.offsetTop + document.body.scrollTop);
    }, false);
    graph.addEventListener('mouseenter', function(event){
      if (!!curData1 && !!curData2)
        bsDiv.style.display='block';
    }, false);
    graph.addEventListener('mouseout', function(event){
      bsDiv.style.display='none';
    }, false);
  }
</script>
</head>

<body>
<div style="width: 100%; display: table;">
    <div style="display: table-row">
        <div style="vertical-align: top; display: table-cell;" id="content"></div>
        <div style="vertical-align: top; width: 600px; display: table-cell;"><canvas width="1800" height="1200" id="graph"/></div>
    </div>
</div>
<div id="box-shadow-div"><canvas width="200" height="200" id="small_graph"/></div>
</body>
<script>
var dataset1=\`$1\`;
var dataset2=\`$2\`;
</script>
<script>root();</script>
</html>
XXX
