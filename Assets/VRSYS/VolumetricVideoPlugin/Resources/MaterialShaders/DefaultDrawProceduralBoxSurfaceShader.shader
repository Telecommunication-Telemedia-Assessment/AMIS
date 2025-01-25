Shader "DrawProceduralBoxOutlinesShader"
{
        SubShader
    {

                  Offset -1, -1
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Back
            CGPROGRAM

  

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
              float4 pos : SV_POSITION;
              float3 uvw : COLOR0;
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

                const uint cube_tri_indices[36] = {
                    // front
                    0u, 1u, 2u,
                    0u, 2u, 3u,
                    
                    1u, 5u, 6u,
                    1u, 6u, 2u,


                    5u, 4u, 7u,
                    5u, 7u, 6u,

                    4u, 0u, 3u,
                    4u, 3u, 7u,

                    5u, 0u, 4u,
                    5u, 1u, 0u,

                    6u, 7u, 3u,
                    6u, 3u, 2u
                };


                float3 pos = generalized_cube_vertices[cube_tri_indices[vertexID]]; //_Positions[vertexID];

                float4 wpos = mul(_ObjectToWorld, float4(pos , 1.0f));

                v2f o;
                o.pos = mul(UNITY_MATRIX_VP, wpos);
                o.uvw = pos;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {

                float4 out_color = float4(0.0, 0.302, 0.443, 1.0);
                float3 in_uvw = i.uvw;


                out_color.xyz = in_uvw;
                float thickness = 0.12f;
                float3 abs_coord = fmod(in_uvw, 1.0 - thickness);//  clamp(1.0 - c, 0.0, 1.0);//abs();
                bool3 tex_dim_larger_than_thickness = abs_coord > thickness;

                uint num_dims_contained = 0;
                for (uint dim_idx = 0; dim_idx < 3; ++dim_idx) {
                    if (tex_dim_larger_than_thickness[dim_idx]) {
                        ++num_dims_contained;
                    }
                }
                //out_color.xyz

                bool is_not_part_of_skeleton = !(num_dims_contained < 2);

                if (is_not_part_of_skeleton) {
                    discard;
                }


                return (0.5f + 0.5f * _SinTime.x) * float4(0.0, 0.302, 0.443, 1.0); //fmod(out_color + _SinTime.z, 1.0f);
            }
            ENDCG
        }




    }
}