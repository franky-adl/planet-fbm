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
uniform float freq_up_factor;
uniform float amp_down_factor;
varying vec2 vUv;
varying vec3 vNormal;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

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
  vec3 color = vec3(0.052,0.052,0.431 + cnoise(vec2(1.,vUv.y*10.))/4.);

  // q being the result of the first run of fbm
  float warper = fbm( st + vec2(timeMul * u_time,0.), 1, 4);
  float warped = fbm( st + vec2(warper, 0.) + timeMul * u_time , 3, 5);
  // gl_FragColor = vec4(mix(color, vec3(warped), cubicPulse(warper, 0.1, vUv.y)), 1.0);
  float mixFactor = cubicPulse(0.53 + warper/50., 0.01 + warped/100., vUv.y);
  mixFactor += cubicPulse(0.48 + warper/70., 0.03 + warped/100., vUv.y);
  // mixFactor += cubicPulse(0.53, 0.003 + warper/100., vUv.y);
  gl_FragColor = vec4(mix(color, vec3(0.884,0.896,0.694), mixFactor), 1.0);

  // adding a small amount of atmospheric fresnel effect to make it more realistic
  // fine tune the first constant below for stronger or weaker effect
  float intensity = 1.4 - dot( vNormal, vec3( 0.0, 0.0, 1.0 ) );
  vec3 atmosphere = vec3(0.078,0.596,0.157) * pow(intensity, 5.0);

  gl_FragColor.rgb += atmosphere;
}