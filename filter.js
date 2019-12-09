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

	this.redraw = function() {
		filter.squareWave();
		filter.makeSinc();
		filter.calcFilter();
		filter.drawWaves();
	}

	this.squareWave = function() {
		this.samples.length = 0;
		for (var s = 0; s < 400; s++) {
			this.samples.push(100 * (s % this.samplecount > (this.samplecount / 2) ? 1 : -1)); 
		}
	}

	this.makeSinc = function() {
		this.filterCutOff = document.getElementById("filtAmt").value;
		this.sincSize = document.getElementById("sincSize").value;

		this.sinc.length = 0;
		for (var s = 0; s < this.sincSize; s++) {
			var denom = this.filterCutOff * Math.PI * (s - (this.sincSize / 2));
			var sinc = 
			this.sinc.push(denom == 0 ? 1 : Math.sin(denom) / denom); 
		}
	}


	this.calcFilter = function() {
		
		var filterType = document.querySelector('input[name="filtType"]:checked').value;
		
		this.filtered.length = 0;
		
		switch (filterType) {
		case "sinc":
		
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
			break;
			
		case "movAv":
			for (var s = 0; s < this.samples.length; s++) {
				if (s < this.sincSize / 2 || s > this.samples.length - (this.sincSize / 2)) {
					this.filtered.push(0);
				} else {
					var sum = 0;
					for (var f = 0; f < this.sincSize;  f++) {
						sum += this.samples[s - (this.sincSize / 2) + f];
					}
					this.filtered.push(sum / this.sincSize);
				}
			}
			break;
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

	this.drawSinc = function() {
		viewport.clear();
		context = viewport.ctx;
		this.makeSinc();

		var vertOffset = 250;

		// Draw zero line
		context.beginPath(); 
		context.moveTo(0, vertOffset);
		context.lineTo(this.sincSize * 4, vertOffset);
		context.strokeStyle = "grey";
		context.stroke();			

		
		for (var f = 0; f < this.sincSize;  f++) {
			context.beginPath(); 
			context.moveTo(f * 4, vertOffset - (this.sinc[f] * 200));
			context.lineTo((f + 1) * 4, vertOffset - (this.sinc[f + 1] * 200));
			context.strokeStyle = "green";
			context.stroke();			
		}
	}
}


var filter = new filter();
filter.redraw();