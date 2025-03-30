//
//  Shaders.metal
//  ParticleSimulator
//
//  Created by 이종선 on 3/30/25.
//

#include <metal_stdlib>
using namespace metal;

// 정점 쉐이더 입력 구조체
//정점 쉐이더로 들어오는 원시 데이터를 정의합니다.
//이 예제에서는 실제로 정점 쉐이더가 buffer를 직접 읽고 있어서 VertexIn이 사용되지 않습니다만, 일반적으로는 GPU에 올라간 정점 데이터의 형식을 정의하는 데 사용됩니다.
//[[attribute(0)]], [[attribute(1)]]과 같은 어트리뷰트는 GPU가 정점 버퍼에서 어떤 데이터를 어떤 위치에서 가져와야 하는지 지정합니다.
struct VertexIn {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

// 정점 쉐이더 출력 및 프래그먼트 쉐이더 입력 구조체
//정점 쉐이더에서 나가는 데이터와 프래그먼트 쉐이더로 들어가는 데이터를 정의합니다.
//이것은 두 쉐이더 단계 사이의 "계약"이나 "인터페이스"라고 볼 수 있습니다.
//[[position]] 어트리뷰트는 이 값이 화면 좌표계의 위치 데이터임을 GPU에게 알려줍니다.
struct VertexOut {
    float4 position [[position]];
    float4 color;
};

// 정점 쉐이더 함수
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                             constant float* vertices [[buffer(0)]]) {
    VertexOut out;
    
    // 정점 데이터 파싱 (매 정점마다 7개의 float 값)
    float3 position = float3(vertices[vertexID * 7 + 0],
                            vertices[vertexID * 7 + 1],
                            vertices[vertexID * 7 + 2]);
    
    float4 color = float4(vertices[vertexID * 7 + 3],
                         vertices[vertexID * 7 + 4],
                         vertices[vertexID * 7 + 5],
                         vertices[vertexID * 7 + 6]);
    
    out.position = float4(position, 1.0);
    out.color = color;
    
    return out;
}

// 프래그먼트 쉐이더 함수
fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
