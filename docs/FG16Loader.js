const U8toU32 = (arr,offset)=>{ return arr[offset+3]<<24|arr[offset+2]<<16|arr[offset+1]<<8|arr[offset]; };
const U32 = new Uint32Array(1);
const U16toF32 = (u16)=>{
	U32[0] = (u16&0x8000)<<16|((((u16>>10)&0x1F)-15+127)&0xFF)<<23|(u16&0x3FF)<<13;
	return (new Float32Array(U32.buffer))[0];
}

export const FGLoader = Object.freeze({
	
	parse:(url,data,init)=>{
		
		const U8 = new Uint8Array(data);
		
		if(new TextDecoder().decode(U8.slice(0,4))==="FG16") {
			
			const size = U8toU32(U8,4*3);
			if(new TextDecoder().decode(U8.slice(4*4,4*4+4))==="JSON") {
				const json = JSON.parse(new TextDecoder().decode(U8.slice(4*5,4*5+size)));
				if(new TextDecoder().decode(U8.slice(4*5+size+4*1,4*5+size+4*1+3))==="BIN") {
					
					const offset = 4*5+size+4*2;
					const bufferViews = json["bufferViews"];
					const byteOffsets = [bufferViews[0]["byteOffset"],bufferViews[1]["byteOffset"],bufferViews[2]["byteOffset"]];
					const byteLengths = [bufferViews[0]["byteLength"],bufferViews[1]["byteLength"],bufferViews[2]["byteLength"]];
					
					if(+(json["accessors"][0]["count"])===+(json["accessors"][1]["count"])) {
						
						const U16 = (new Uint16Array(data)).slice(offset>>1);
						
						const v16  = U16.slice(byteOffsets[0]>>1,(byteOffsets[0]+byteLengths[0])>>1);
						const vt16 = U16.slice(byteOffsets[1]>>1,(byteOffsets[1]+byteLengths[1])>>1);
						
						
						const len = +(json["accessors"][0]["count"]);
						if(len<=0xFFFF) {
							const v = new Float32Array(len*3);
							for(var n=0; n<v.length; n++) {
								v[n] = U16toF32(v16[n]);
							}
							
							const vt = new Float32Array(len*2);
							for(var n=0; n<vt.length; n++) {
								vt[n] = U16toF32(vt16[n]);
							}
							
							const f = new Uint32Array(len);
							for(var n=0; n<f.length; n++) {
								f[n] = n;
							}
							
							const image = U8.slice(offset+byteOffsets[2],offset+byteOffsets[2]+byteLengths[2]);
							const result = {};
							result[url] = {
								"v":v,
								"vt":vt,
								"f":f,
								"img":URL.createObjectURL(new Blob([image.buffer],{type:json["images"][0]["mimeType"]})),
								"bytes":4
							}
							
							init(result);
						}
						else {
							
							init(null);
						}
					}
				}
			}
		}
	},
	
	load:(url,init)=>{
		
		let list = [];
		
		if(typeof(url)==="string") {
			list.push(url);
		}
		else if(Array.isArray(url)) {
			list = url;
		}
						
		if(list.length>=1) {
			
			let loaded = 0;
			let data = {};
			
			const onload = (result) => {
				if(result) {
					const key = Object.keys(result)[0];
					data[key] = result[key];
					loaded++;
					if(loaded===list.length) {
						init(data);
					}
				}
			};
			
			const load = (url) => {
				fetch(url).then(response=>response.blob()).then(data=>{
					const fr = new FileReader();
					fr.onloadend = ()=>{
						FGLoader.parse(url,fr.result,onload);
					};
					fr.readAsArrayBuffer(data)
				}).catch(error=>{
					console.error(error);
				});
			}
			
			for(var n=0; n<list.length; n++) {
				load(list[n]);
			}
		}
	}
});