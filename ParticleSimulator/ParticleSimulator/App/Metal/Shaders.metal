//
//  Shaders.metal
//  ParticleSimulator
//
//  Created by 이종선 on 3/30/25.
//


#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOutput vertexShader(uint vertexID [[vertex_id]],
                              constant float *vertices [[buffer(0)]]) {
    VertexOutput output;
    
    // 정점 데이터에서 위치와 텍스처 좌표 추출
    float3 position = float3(vertices[vertexID * 5 + 0], vertices[vertexID * 5 + 1], vertices[vertexID * 5 + 2]);
    float2 texCoord = float2(vertices[vertexID * 5 + 3], vertices[vertexID * 5 + 4]);
    
    output.position = float4(position, 1.0);
    output.texCoord = texCoord;
    
    return output;
}

fragment float4 fragmentShader(VertexOutput in [[stage_in]],
                             texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, in.texCoord);
}
