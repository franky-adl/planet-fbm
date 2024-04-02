#ifdef GL_ES
precision mediump float;
#endif

#pragma glslify: snoise = require('./simplex2d.glsl')
#pragma glslify: noise = require('./value2d.glsl')
#pragma glslify: voronoi = require('./voronoi2d.glsl')
#pragma glslify: cnoise = require('./perlin2d.glsl')

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform float scale;
uniform float shift;
uniform float rot_angle;
// uniform int octaves;
uniform float freq_up_factor;
uniform float amp_down_factor;
varying vec2 vUv;

float cubicPulse( float c, float w, float x ){
  x = abs(x - c);
  if( x>w ) return 0.0;
  x /= w;
  return 1.0 - x*x*(3.0-2.0*x);
}

float fbm ( in vec2 _st, int noiseFlag, int octaves ) {
  // v is the final result
  float v = 0.0;
  // a means amplitude of the octave
  float a = 0.5;
  mat2 rot = mat2(cos(rot_angle), sin(rot_angle),
                  -sin(rot_angle), cos(rot_angle));
  for (int i = 0; i < octaves; ++i) {
    // adds amplituded noise to the final accumulated result v
    if (noiseFlag == 0) {
      v += a * noise(_st);
    } else if (noiseFlag == 1) {
      v += a * (snoise(_st) * 0.5 + 0.5);
    } else if (noiseFlag == 2) {
      v += a * voronoi(_st);
    } else if (noiseFlag == 3) {
      v += a * snoise(_st);
    } else if (noiseFlag == 4) {
      v += a * cnoise(_st);
    }
    // Rotate to reduce axial bias,
    // up frequency 2 times
    // shift the coordinates
    _st = rot * _st * freq_up_factor + vec2(shift);
    // half the amplitude for next round
    a *= amp_down_factor;
  }
  return v;
}

void main() {
  float timeMul = 0.05;
  float timeMul2 = 0.15;
  // vec2 st = gl_FragCoord.xy/u_resolution.xy*3.;
  vec2 st = vec2(vUv.x * 8., vUv.y * 4.) * scale;
  // st += st * abs(sin(u_time*0.1)*3.0);
  vec3 color = vec3(0.0);

  // q being the result of the first run of fbm
  vec2 q = vec2(0.);
  q.x = fbm( st , 2, 5);
  q.y = fbm( st + vec2(1.) , 2, 5);
  // gl_FragColor = vec4(vec3(overlay), 1.0);

  // 5-oct perlin warper
  float b = fbm( st + vec2(timeMul * u_time, 0.), 4, 5 );
  // planet texture, 4-oct simplex warped by the above warper
  // note that if you want the warped texture to move horizontally with time instead of "bubbling",
  // you need to speed up st to the same degree in both the warper and the warpee
  float pt = fbm( st + vec2(b, 0)+ vec2(timeMul * u_time, 0.), 1, 4);

  // r being the result of 2nd run of fbm, with input of the 1st run: q, and time
  vec2 r = vec2(0.);
  r.x = fbm( st + 1.0*q + vec2(1.3,8.0)+ vec2(timeMul*u_time, 0.), 3, 1 );
  r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*u_time, 3, 1 );

  // cloud overlay using classic perlin noise warped by voronoi noise
  float overlay = cnoise(st/vec2(2.) + q + vec2(timeMul2*u_time, 0.));
  overlay = smoothstep(0.2, 0.8, overlay);
  // gl_FragColor = vec4(vec3(overlay), 1.0);

  float f = pt;
  // gl_FragColor = vec4(vec3(pt), 1.0);

  // bring in a brown-yellow pattern
  color = mix(vec3(0.675,0.435,0.141),
              vec3(0.902,0.871,0.145),
              clamp(f*f*1.5,0.,1.));

  // bring in some bluish highlights
  color = mix(color,
              vec3(0,0,0.164706),
              clamp(f*f*f,0.,1.));

  // multiplying a cubic polynomial of the final result f with color intensifies the details and contrasts of the color
  gl_FragColor = vec4((f*f*f+.6*f*f+.5*f)*color + vec3(overlay),1.);
  
  // outputs in sRGB space
  gl_FragColor = linearToOutputTexel( gl_FragColor );
}