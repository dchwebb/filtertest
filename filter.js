var vpWidth = 800;
var vpHeight = 400;
document.getElementById('c').width = vpWidth;
document.getElementById('c').height = vpHeight;

vpObj = function() {
	this.canvas = document.getElementById('c');
	this.ctx = this.canvas.getContext('2d');
	this.clear = function() {
		this.ctx.clearRect(0, 0, vpWidth, vpHeight);
	}
}
var viewport = new vpObj();

filter = function() {
	this.sincSize = 64;
	this.filterCutOff = 0.1;
	this.samplecount = 128;
	this.samples = [];
	this.sinc = [];
	this.filtered = [];
	
	this.squareWave = function() {
		this.samples.length = 0;
		for (var s = 0; s < 400; s++) {
			this.samples.push(100 * (s % this.samplecount > (this.samplecount / 2) ? 1 : -1)); 
		}
	}

	this.makeSinc = function() {
		this.sinc.length = 0;
		for (var s = 0; s < this.sincSize; s++) {
			var denom = this.filterCutOff * Math.PI * (s - (this.sincSize / 2));
			var sinc = 
			this.sinc.push(denom == 0 ? 1 : Math.sin(denom) / denom); 
		}
	}
	
	this.calcFilter = function() {
		this.filtered.length = 0;
		// Navigate all samples except those at beginning and end outside sinc window
		for (var s = 0; s < this.samples.length; s++) {
			if (s < this.sincSize / 2 || s > this.samples.length - (this.sincSize / 2)) {
				this.filtered.push(0);
			} else {
				var norm = 0;
				var mac = 0;
				for (var f = 0; f < this.sincSize;  f++) {
					norm += this.sinc[f];
					mac += this.sinc[f] * this.samples[s - (this.sincSize / 2) + f];
				}
				this.filtered.push(mac / norm);
			}
		}
	}
	
	this.drawWaves = function() {
		//loops through all the planes in universe, updates position then draws shape.
		viewport.clear();

		context = viewport.ctx;
		context.fillStyle = "blue";
		for (var s = 0; s < this.samples.length; s++) {
			//context.fillRect(s, this.samples[s] + 200, 1, 1);

			context.beginPath(); 
			context.moveTo(s * 2, this.samples[s] + 200);
			context.lineTo((s + 1) * 2,this.samples[s + 1] + 200);
			context.strokeStyle = "blue";
			context.stroke();
		}

		for (var s = 0; s < this.filtered.length; s++) {
			context.beginPath(); 
			context.moveTo(s * 2, this.filtered[s] + 200);
			context.lineTo((s + 1) * 2,this.filtered[s + 1] + 200);
			context.strokeStyle = "red";
			context.stroke();
		}

	}

}

function toRadians(angle) {
	return angle * (Math.PI / 180);
}
function toDegrees(angle) {
	return posAng(angle * (180 / Math.PI));
}
var filter = new filter();

function Redraw() {
	filter.squareWave();
	filter.makeSinc();
	filter.calcFilter();
	filter.drawWaves();
}
