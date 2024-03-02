varying vec2 vUv;
varying vec3 vNormal;

void main() {
    // modelMatrix transforms the coordinates local to the model into world space
    vec4 worldPos = modelMatrix * vec4(position, 1.0);
    // viewMatrix transform the world coordinates into the world space viewed by the camera (view space)
    vec4 mvPosition = viewMatrix * worldPos;

    // normalMatrix transforms the normal vectors local to the model into view space
    vec3 transformedNormal = normalMatrix * normal;
    vNormal = normalize(transformedNormal);

    vUv = uv;

    gl_Position = projectionMatrix * mvPosition;
}