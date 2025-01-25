Shader "DrawProceduralBoxOutlinesShader"
{
        SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
              float4 pos : SV_POSITION;
            };

            uniform float4x4 _ObjectToWorld;


            v2f vert(uint vertexID: SV_VertexID)
            {

                const float3 generalized_cube_vertices[8] = {
                    // front
                    {-0.0, -0.0,  1.0}, //0
                    { 1.0, -0.0,  1.0}, //1
                    { 1.0,  1.0,  1.0}, //2
                    {-0.0,  1.0,  1.0}, //3
                    // back
                    {-0.0, -0.0, -0.0}, //4
                    { 1.0, -0.0, -0.0}, //5
                    { 1.0,  1.0, -0.0}, //6
                    {-0.0,  1.0, -0.0}  //7
                };

                const uint cube_indices[24] = {
                    // front
                    0u, 1u,
                    1u, 2u,
                    2u, 3u,
                    3u, 0u,

                    // back
                    4u, 5u,
                    5u, 6u,
                    6u, 7u,
                    7u, 4u,

                    //front to back
                    0u, 4u,
                    1u, 5u,
                    2u, 6u,
                    3u, 7u 
                };


                float3 pos = generalized_cube_vertices[cube_indices[vertexID]]; //_Positions[vertexID];

                float4 wpos = mul(_ObjectToWorld, float4(pos , 1.0f));

                v2f o;
                o.pos = mul(UNITY_MATRIX_VP, wpos);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {

                float4 out_color = float4(0.0, 0.302, 0.443, 1.0);

                return out_color;
            }
            ENDCG
        }




    }
}