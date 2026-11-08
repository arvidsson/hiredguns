uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;
uniform bool isCanvasEnabled;
uniform float collapse;

varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 vertexColor;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    vertexPosition.y += vertexPosition.z * collapse * 0.65;
    vertexPosition.z *= 1.0 - 0.84 * collapse;

    worldPosition = modelMatrix * vertexPosition;
    viewPosition = viewMatrix * worldPosition;
    vertexColor = VertexColor;
    vec4 projected = projectionMatrix * viewPosition;
    if (isCanvasEnabled) {
        projected.y *= -1.0;
    }
    return projected;
}
