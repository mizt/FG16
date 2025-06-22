#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <vector>
#import <string>

int main(int argc, char *argv[]) {
    
    @autoreleasepool {
        
        NSString *path = @"./FG.jpg";
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSString *mimeType = nil;
            if([[path pathExtension] isEqualToString:@"png"]) mimeType = @"image/png";
            else if([[path pathExtension] isEqualToString:@"jpg"]||[[path pathExtension] isEqualToString:@"jpeg"]) mimeType = @"image/jpeg";
            
            if(mimeType) {
                
                NSData *_texture = [[NSData alloc] initWithContentsOfFile:path];
                
                NSMutableData *texture = [[NSMutableData alloc] init];
                [texture appendBytes:_texture.bytes length:_texture.length];
                
                // Aligned to 4-byte boundaries.
                while(texture.length%4!=0) {
                    [texture appendBytes:new const char[1]{0x20} length:1];
                }
                
                std::string JSON = R"({"asset":{"generator":"RC","version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],"materials":[{"doubleSided":true,"pbrMetallicRoughness":{"baseColorTexture":{"index":0},"metallicFactor":0,"roughnessFactor":1.0}}],"meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1},"indices":2,"material":0}]}],"textures":[{"sampler":0,"source":0}],"images":[{"bufferView":2,"mimeType":"image/jpeg","name":"texture"}],"accessors":[{"bufferView":0,"componentType":5126,"count":0,"max":[0,0,0],"min":[0,0,0],"type":"VEC3"},{"bufferView":1,"componentType":5126,"count":0,"type":"VEC2"},],"bufferViews":[{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0}],"samplers":[{"magFilter":9729,"minFilter":9987,"wrapS":33071,"wrapT":33071}],"buffers":[{"byteLength":0}]})";
                
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[NSString stringWithUTF8String:JSON.c_str()] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
                
                if(dict) {
                    
                    std::vector<simd::float3> _v;
                    std::vector<simd::float2> _vt;
                    std::vector<simd::uint3> _f1;
                    std::vector<simd::uint3> _f2;
                    
                    std::vector<unsigned short> v16;
                    std::vector<unsigned short> vt16;

                    NSCharacterSet *WHITESPACE = [NSCharacterSet whitespaceCharacterSet];
                    
                
                    NSString *data = [NSString stringWithContentsOfFile:@"./FG.obj" encoding:NSUTF8StringEncoding error:nil];
                    NSArray *lines = [data componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                    
                    int faces = 0;
                    
                    for(int k=0; k<lines.count; k++) {
                        NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:WHITESPACE];
                        if([arr count]>0) {
                            if([arr[0] isEqualToString:@"v"]) {
                                if([arr count]>=4) {
                                    _v.push_back(simd::float3{
                                        [arr[1] floatValue],
                                        [arr[2] floatValue],
                                        [arr[3] floatValue]
                                    });
                                }
                            }
                            else if([arr[0] isEqualToString:@"vt"]) {
                                if([arr count]==3) {
                                    _vt.push_back(simd::float2{
                                        [arr[1] floatValue],
                                        [arr[2] floatValue]
                                    });
                                }
                            }
                            else if([arr[0] isEqualToString:@"f"]) {
                                if([arr count]==4) {
                                    
                                    NSArray *a = [arr[1] componentsSeparatedByString:@"/"];
                                    NSArray *b = [arr[2] componentsSeparatedByString:@"/"];
                                    NSArray *c = [arr[3] componentsSeparatedByString:@"/"];
                                    
                                    _f1.push_back(simd::uint3{
                                        (unsigned int)[a[0] intValue]-1,
                                        (unsigned int)[b[0] intValue]-1,
                                        (unsigned int)[c[0] intValue]-1
                                    });
                                    
                                    _f2.push_back(simd::uint3{
                                        (unsigned int)[a[1] intValue]-1,
                                        (unsigned int)[b[1] intValue]-1,
                                        (unsigned int)[c[1] intValue]-1
                                    });
                                    
                                }
                                else {
                                    NSLog(@"???");
                                }
                            }
                        }
                    }
                    
                    float v_min[3] = {0.0,0.0,0.0};
                    float v_max[3] = {0.0,0.0,0.0};
                    
                    for(int n=0; n<_f1.size(); n++) {
                        
                        _Float16 v[9] = {
                            (_Float16)_v[_f1[n].x].x,(_Float16)_v[_f1[n].x].y,(_Float16)_v[_f1[n].x].z,
                            (_Float16)_v[_f1[n].y].x,(_Float16)_v[_f1[n].y].y,(_Float16)_v[_f1[n].y].z,
                            (_Float16)_v[_f1[n].z].x,(_Float16)_v[_f1[n].z].y,(_Float16)_v[_f1[n].z].z,
                        };
                        
                        if(n==0) {
                            v_min[0] = v[0];
                            v_min[1] = v[1];
                            v_min[2] = v[2];
                            
                            v_max[0] = v[0];
                            v_max[1] = v[1];
                            v_max[2] = v[2];
                        }
                        
                        if(v[0]<v_min[0]) v_min[0] = v[0];
                        if(v[3]<v_min[0]) v_min[0] = v[3];
                        if(v[6]<v_min[0]) v_min[0] = v[6];
                        
                        if(v[1]<v_min[1]) v_min[1] = v[1];
                        if(v[4]<v_min[1]) v_min[1] = v[4];
                        if(v[7]<v_min[1]) v_min[1] = v[7];
                        
                        if(v[2]<v_min[2]) v_min[2] = v[2];
                        if(v[5]<v_min[2]) v_min[2] = v[5];
                        if(v[8]<v_min[2]) v_min[2] = v[8];
                        
                        if(v_max[0]<v[0]) v_max[0] = v[0];
                        if(v_max[0]<v[3]) v_max[0] = v[3];
                        if(v_max[0]<v[6]) v_max[0] = v[6];
                        
                        if(v_max[1]<v[1]) v_max[1] = v[1];
                        if(v_max[1]<v[4]) v_max[1] = v[4];
                        if(v_max[1]<v[7]) v_max[1] = v[7];
                        
                        if(v_max[2]<v[2]) v_max[2] = v[2];
                        if(v_max[2]<v[5]) v_max[2] = v[5];
                        if(v_max[2]<v[8]) v_max[2] = v[8];
                                                
                        v16.push_back(*((unsigned short *)(v+0)));
                        v16.push_back(*((unsigned short *)(v+1)));
                        v16.push_back(*((unsigned short *)(v+2)));
                        
                        v16.push_back(*((unsigned short *)(v+3)));
                        v16.push_back(*((unsigned short *)(v+4)));
                        v16.push_back(*((unsigned short *)(v+5)));
                        
                        v16.push_back(*((unsigned short *)(v+6)));
                        v16.push_back(*((unsigned short *)(v+7)));
                        v16.push_back(*((unsigned short *)(v+8)));
                        
                        _Float16 vt[6] = {
                            (_Float16)_vt[_f2[n].x].x,(_Float16)(1.0-_vt[_f2[n].x].y),
                            (_Float16)_vt[_f2[n].y].x,(_Float16)(1.0-_vt[_f2[n].y].y),
                            (_Float16)_vt[_f2[n].z].x,(_Float16)(1.0-_vt[_f2[n].z].y),
                        };
                        
                        vt16.push_back(*((unsigned short *)(vt+0)));
                        vt16.push_back(*((unsigned short *)(vt+1)));
                        
                        vt16.push_back(*((unsigned short *)(vt+2)));
                        vt16.push_back(*((unsigned short *)(vt+3)));
                        
                        vt16.push_back(*((unsigned short *)(vt+4)));
                        vt16.push_back(*((unsigned short *)(vt+5)));
                    }
                            
                    unsigned int offset = 0;
                    
                    dict[@"images"][0][@"mimeType"] = mimeType;

                    dict[@"bufferViews"][0][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][0][@"byteLength"] = [NSNumber numberWithInt:(v16.size())*sizeof(unsigned short)];
                    
                    for(int n=0; n<3; n++) {
                        dict[@"accessors"][0][@"min"][n] = [NSNumber numberWithInt:v_min[n]];
                        dict[@"accessors"][0][@"max"][n] = [NSNumber numberWithInt:v_max[n]];
                    }
                    
                    dict[@"accessors"][0][@"count"] = [NSNumber numberWithInt:v16.size()/3];
                    NSLog(@"%d",[dict[@"accessors"][0][@"count"] intValue]);
                    
                    while(v16.size()%4!=0) {
                        v16.push_back(0);
                    }
                    offset+=v16.size()*sizeof(unsigned short);
                    
                    dict[@"bufferViews"][1][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][1][@"byteLength"] = [NSNumber numberWithInt:vt16.size()*sizeof(unsigned short)];
                    dict[@"accessors"][1][@"count"] = [NSNumber numberWithInt:vt16.size()/2];
                    NSLog(@"%d",[dict[@"accessors"][1][@"count"] intValue]);
                    
                    while(vt16.size()%4!=0) {
                        vt16.push_back(0);
                    }
                    offset+=vt16.size()*sizeof(unsigned short);
                    
                    dict[@"bufferViews"][2][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][2][@"byteLength"] = [NSNumber numberWithInt:texture.length];
                    offset+=texture.length;
                    
                    dict[@"buffers"][0][@"byteLength"] = [NSNumber numberWithInt:offset];
                    
                    NSMutableData *json = [[NSMutableData alloc] init];
                    [json appendData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingWithoutEscapingSlashes|NSJSONWritingSortedKeys error:nil]];
                    
                    while(json.length%4!=0) {
                        [json appendBytes:new const char[1]{0x20} length:1];
                    }
                    
                    NSMutableData *glb = [[NSMutableData alloc] init];
                    [glb appendBytes:new const char[4]{'g','l','T','F'} length:4];
                    [glb appendBytes:new unsigned int[1]{2} length:4];
                    [glb appendBytes:new unsigned int[1]{((4*7)+(unsigned int)json.length)+offset} length:4];
                    [glb appendBytes:new unsigned int[1]{(unsigned int)json.length} length:4];
                    [glb appendBytes:new const char[4]{'J','S','O','N'} length:4];
                    [glb appendBytes:json.bytes length:json.length];
                    [glb appendBytes:new unsigned int[1]{offset} length:4];
                    [glb appendBytes:new const char[4]{'B','I','N',0} length:4];
                    [glb appendBytes:v16.data() length:v16.size()*sizeof(unsigned short)];
                    [glb appendBytes:vt16.data() length:vt16.size()*sizeof(unsigned short)];
                    [glb appendBytes:texture.bytes length:texture.length];
                    
                    [glb writeToFile:@"./docs/FG.bin" atomically:YES];
                    
                    glb = nil;
                    json = nil;
                    dict = nil;

                    //v.clear();
                    //v.shrink_to_fit();
                    //vt.clear();
                    //vt.shrink_to_fit();
                    //f.clear();
                    //f.shrink_to_fit();
                }
            }
        }
    }
}