//
//  Shaders.metal
//  ParticleSimulator
//
//  Created by 이종선 on 3/30/25.
//


#include <metal_stdlib>
using namespace metal;

// Swift와 공유하는 데이터 구조체
struct Particle {
    uint isEmpty;
    uint type;
};

struct Color {
    uchar r;
    uchar g;
    uchar b;
    uchar a;
};

struct SimulationParams {
    uint width;
    uint height;
    uint frameCount;
};

// 입자 타입 열거형
enum ParticleType {
    Empty = 0,
    Sand = 1,
    Water = 2
};

// 렌더링 관련 구조체
struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
};

// 렌더링을 위한 버텍스 셰이더
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

// 텍스처 렌더링을 위한 프래그먼트 셰이더
fragment float4 fragmentShader(VertexOutput in [[stage_in]],
                             texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, in.texCoord);
}

// 입자 위치 조회 헬퍼 함수
uint getIndex(uint2 pos, uint width) {
    return pos.y * width + pos.x;
}

// 안전하게 입자 접근 (경계 확인)
bool isInBounds(uint2 pos, uint width, uint height) {
    return pos.x < width && pos.y < height;
}

// 입자 이동 헬퍼 함수
void moveParticle(device Particle* particles,
                  device Color* colors,
                  uint fromIndex,
                  uint toIndex) {
    particles[toIndex] = particles[fromIndex];
    colors[toIndex] = colors[fromIndex];
    
    particles[fromIndex].isEmpty = 1;
    particles[fromIndex].type = ParticleType::Empty;
    colors[fromIndex] = Color{0, 0, 0, 0};
}

// 입자 시뮬레이션 컴퓨트 셰이더
kernel void updateParticles(device Particle* particles [[buffer(0)]],
                           device Color* colors [[buffer(1)]],
                           constant SimulationParams& params [[buffer(2)]],
                           uint2 pos [[thread_position_in_grid]]) {
    
    // 범위 확인
    if (pos.x >= params.width || pos.y >= params.height) {
        return;
    }
    
    // 입자 인덱스
    uint index = getIndex(pos, params.width);
    
    // 빈 공간이면 건너뛰기
    if (particles[index].isEmpty == 1) {
        return;
    }
    
    // 프레임 고유성 - 홀수/짝수 프레임에 따라 다른 방향으로 처리
    bool evenFrame = (params.frameCount % 2) == 0;
    
    // 입자 타입에 따른 처리
    if (particles[index].type == ParticleType::Sand) {
        // 아래쪽 위치
        uint2 below = uint2(pos.x, pos.y + 1);
        
        // 화면 바닥에 도달했는지 확인
        if (!isInBounds(below, params.width, params.height)) {
            return;
        }
        
        uint belowIndex = getIndex(below, params.width);
        
        // 아래로 이동 가능한지 확인
        if (particles[belowIndex].isEmpty == 1) {
            moveParticle(particles, colors, index, belowIndex);
            return;
        }
        
        // 왼쪽 아래 및 오른쪽 아래 위치
        uint2 belowLeft = uint2(pos.x - 1, pos.y + 1);
        uint2 belowRight = uint2(pos.x + 1, pos.y + 1);
        
        // 짝수 프레임에는 왼쪽 우선, 홀수 프레임에는 오른쪽 우선 (더 자연스러운 흐름)
        if (evenFrame) {
            // 왼쪽 아래로 이동 가능한지 확인
            if (pos.x > 0 && isInBounds(belowLeft, params.width, params.height)) {
                uint belowLeftIndex = getIndex(belowLeft, params.width);
                if (particles[belowLeftIndex].isEmpty == 1) {
                    moveParticle(particles, colors, index, belowLeftIndex);
                    return;
                }
            }
            
            // 오른쪽 아래로 이동 가능한지 확인
            if (pos.x < params.width - 1 && isInBounds(belowRight, params.width, params.height)) {
                uint belowRightIndex = getIndex(belowRight, params.width);
                if (particles[belowRightIndex].isEmpty == 1) {
                    moveParticle(particles, colors, index, belowRightIndex);
                    return;
                }
            }
        } else {
            // 오른쪽 아래로 이동 가능한지 확인
            if (pos.x < params.width - 1 && isInBounds(belowRight, params.width, params.height)) {
                uint belowRightIndex = getIndex(belowRight, params.width);
                if (particles[belowRightIndex].isEmpty == 1) {
                    moveParticle(particles, colors, index, belowRightIndex);
                    return;
                }
            }
            
            // 왼쪽 아래로 이동 가능한지 확인
            if (pos.x > 0 && isInBounds(belowLeft, params.width, params.height)) {
                uint belowLeftIndex = getIndex(belowLeft, params.width);
                if (particles[belowLeftIndex].isEmpty == 1) {
                    moveParticle(particles, colors, index, belowLeftIndex);
                    return;
                }
            }
        }
    }
    
    // 물 입자 처리 로직은 나중에 추가할 수 있음
}
