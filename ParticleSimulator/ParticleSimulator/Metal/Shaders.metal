//
//  Shaders.metal
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

#include <metal_stdlib>
using namespace metal;

// 정점 셰이더 입력 구조체
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

// 정점 셰이더 출력 구조체 (프래그먼트 셰이더 입력)
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// 정점 셰이더
vertex VertexOut vertexShader(const VertexIn vertexIn [[stage_in]]) {
    VertexOut vertexOut;
    vertexOut.position = float4(vertexIn.position, 0.0, 1.0);
    vertexOut.texCoord = vertexIn.texCoord;
    return vertexOut;
}

// 프래그먼트 셰이더
fragment float4 fragmentShader(VertexOut fragmentIn [[stage_in]],
                              texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, fragmentIn.texCoord);
}

// 컴퓨트 셰이더 (입자 시뮬레이션용)
struct Particle {
    float2 position;
    float2 velocity;
    float4 color;
    uint materialType;
    float lifetime;
    uint padding;
};

// 시뮬레이션 파라미터
struct SimulationParams {
    float deltaTime;
    float gravity;
    uint gridWidth;
    uint gridHeight;
};

kernel void updateParticles(device Particle *particles [[buffer(0)]],
                           constant SimulationParams &params [[buffer(1)]],
                           texture2d<float, access::write> outputTexture [[texture(0)]],
                           uint2 id [[thread_position_in_grid]]) {
    // 그리드 내부인지 확인
    if (id.x >= params.gridWidth || id.y >= params.gridHeight) {
        return;
    }
    
    // 입자 인덱스 계산
    uint index = id.y * params.gridWidth + id.x;
    Particle particle = particles[index];
    
    // 입자 유형에 따른 처리 (0은 빈 공간)
    if (particle.materialType == 0) {
        outputTexture.write(float4(0, 0, 0, 0), id);
        return;
    }
    
    // 입자 업데이트 및 렌더링 로직
    // (이 부분은 나중에 구현)
    
    // 간단한 렌더링 (색상 표시)
    outputTexture.write(particle.color, id);
}

