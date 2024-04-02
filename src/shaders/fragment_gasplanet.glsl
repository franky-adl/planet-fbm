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

// https://thebookofshaders.com/edit.php#05/cubicpulse.frag , www.iquilezles.org/www/articles/functions/functions.htm
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
  float rot_angle = 1.0;
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
    _st = rot * _st * 2. + vec2(shift);
    // half the amplitude for next round
    a *= 0.5;
  }
  return v;
}

void main() {
  float timeMul = 0.05;
  float timeMul2 = 0.15;

  vec2 st = vec2(vUv.x * 8., vUv.y * 4.) * scale;
  // set dark-blue as base color, and use perlin noise over y-axis to create horizontal bands
  vec3 planetColor = vec3(0.052,0.052,0.431 + cnoise(vec2(1.,vUv.y*10.))/4.);

  // ELI5: the fbms below are for making the cloud bands
  // the idea of warper and warped here might be unintuitive
  // since warped is resulted from applying 2nd fbm to the warper's result, sounds like the 1st fbm should be called warped instead
  // but giving it some more thought, it actually makes sense
  // let's start from the warped, if st ain't added with the warper's result
  // it would be just the noise it wants to be, say a voronoi pattern
  // but by adding the warper's result to its st, you are basically twisting the coordinates in the warper's pattern
  // essentially it's the 1st fbm's result that "warps" the 2nd fbm's result

  // warper: fbm of normalized simplex noise(1) and 4 octaves
  float warper = fbm( st + vec2(timeMul * u_time,0.), 1, 4);
  // warped: fbm of darkened simplex noise(3) and 5 octaves
  float warped = fbm( st + vec2(warper, 0.) + timeMul * u_time , 3, 5);

  // Usage of cubicPulse here: cubicPulse(x-coord of the pulse climax, width of the pulse, the variable representing x-coords)
  // by adding a scaled-down warper to the pulse's climax position, the band would be twisted 
  // by adding another scaled-down warper to the width, the band exhibits flakier edges
  vec3 bandColor = vec3(0.884,0.896,0.694);
  // 1st band
  float mixFactor = cubicPulse(0.53 + warper/50., 0.01 + warped/100., vUv.y);
  // 2nd band, lower but wider
  mixFactor += cubicPulse(0.48 + warper/70., 0.03 + warped/100., vUv.y);
  // add the bands to the planet
  gl_FragColor = vec4(mix(planetColor, bandColor, mixFactor), 1.0);

  // Adding a small amount of atmospheric fresnel effect to make it more realistic
  // fine tune the first constant below for stronger or weaker effect
  float intensity = 1.4 - dot( vNormal, vec3( 0.0, 0.0, 1.0 ) );
  vec3 atmosphere = vec3(0.078,0.596,0.157) * pow(intensity, 5.0);

  gl_FragColor.rgb += atmosphere;
}