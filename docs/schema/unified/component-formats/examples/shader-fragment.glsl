// Component: shader
// Content-Type: text/x-glsl
// Shader-Stage: fragment

#version 450

// Input from vertex shader
layout(location = 0) in vec3 fragPosition;
layout(location = 1) in vec3 fragNormal;
layout(location = 2) in vec2 fragTexCoord;

// Output
layout(location = 0) out vec4 outColor;

// Uniforms
layout(set = 0, binding = 0) uniform CameraUBO {
    mat4 view;
    mat4 projection;
    vec3 cameraPosition;
} camera;

layout(set = 1, binding = 0) uniform MaterialUBO {
    vec4 baseColor;
    float roughness;
    float metallic;
    float ambientOcclusion;
} material;

// Textures
layout(set = 1, binding = 1) uniform sampler2D albedoMap;
layout(set = 1, binding = 2) uniform sampler2D normalMap;
layout(set = 1, binding = 3) uniform sampler2D roughnessMap;

// Lighting
layout(set = 2, binding = 0) uniform LightUBO {
    vec3 direction;
    vec3 color;
    float intensity;
} sun;

// PBR Constants
const float PI = 3.14159265359;

// Fresnel-Schlick approximation
vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// GGX Distribution
float distributionGGX(vec3 N, vec3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return a2 / denom;
}

void main() {
    // Sample textures
    vec4 albedo = texture(albedoMap, fragTexCoord) * material.baseColor;
    float roughness = texture(roughnessMap, fragTexCoord).r * material.roughness;

    // Normal mapping
    vec3 N = normalize(fragNormal);
    vec3 V = normalize(camera.cameraPosition - fragPosition);
    vec3 L = normalize(-sun.direction);
    vec3 H = normalize(V + L);

    // PBR calculation
    vec3 F0 = mix(vec3(0.04), albedo.rgb, material.metallic);
    vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    float NDF = distributionGGX(N, H, roughness);
    float NdotL = max(dot(N, L), 0.0);

    // Combine
    vec3 diffuse = albedo.rgb * (1.0 - material.metallic);
    vec3 specular = F * NDF;

    vec3 color = (diffuse + specular) * sun.color * sun.intensity * NdotL;

    // Ambient
    vec3 ambient = albedo.rgb * 0.03 * material.ambientOcclusion;
    color += ambient;

    // Tone mapping
    color = color / (color + vec3(1.0));

    // Gamma correction
    color = pow(color, vec3(1.0 / 2.2));

    outColor = vec4(color, albedo.a);
}
