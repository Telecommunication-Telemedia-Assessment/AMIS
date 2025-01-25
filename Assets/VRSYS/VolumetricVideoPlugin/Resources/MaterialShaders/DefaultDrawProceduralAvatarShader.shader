Shader "ExampleShader"
{
    Properties
    {
        _colorRenderTexture("Color Render Texture (Generated)", 2DArray) = "" {}
    }

    SubShader
    {
        Pass
        {
            Cull Front
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            //interpolants
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 uv_plus_layer : COLOR1;
                float4 vertex_colors : TEXCOORD0;

            };

            //actual layered color texture
            UNITY_DECLARE_TEX2DARRAY(_colorRenderTexture);
            
            StructuredBuffer<int> _Triangles;
            StructuredBuffer<uint> _Positions;
            StructuredBuffer<uint> _UVs;
            uniform float4x4 _ObjectToWorld;

            uniform float4 _GeometryQuantBBMin;
            uniform float4 _GeometryQuantBBMax;

            v2f vert(uint vertexID: SV_VertexID, uint instanceID : SV_InstanceID)
            {
                uint quantized_position = _Positions[vertexID];

                float3 bb_extents = _GeometryQuantBBMax - _GeometryQuantBBMin;
                float3 bb_step_size = bb_extents / float3(1023.0, 4095.0, 1023.0);

                float3 dequantized_position = float3( ((quantized_position >> 22) & 0x3FF) * bb_step_size[0], ((quantized_position >> 10) & 0xFFF) * bb_step_size[1], ((quantized_position ) & 0x3FF) * bb_step_size[2] );

                float3 pos = dequantized_position + _GeometryQuantBBMin;
                float4 wpos = mul(_ObjectToWorld, half4(pos, 1.0f));
                v2f o;

                o.pos = mul(UNITY_MATRIX_VP, wpos);
                
                uint quantized_uvs = _UVs[vertexID];

                float4 vertex_colors_to_write = float4(0.0, 0.0, 0.0, 0.0);


                //if vertices are in vertex color mode, unpack the vertex color
                if (0 != (quantized_uvs & 0x80000000) ) {
                    float3 unpacked_vertex_colors = float3(( (quantized_uvs >> 16) & 0xFF) / 255.0, ( (quantized_uvs >> 8) & 0xFF) / 255.0, (quantized_uvs & 0xFF) / 255.0);
                    vertex_colors_to_write = float4(unpacked_vertex_colors, 1.0);

                } else { //else /dequantized UVs packed into UInts
                
                    
                    float3 dequantized_uvs = float3(0.0, 0.0, 0.0);
                    dequantized_uvs[0] = float( (quantized_uvs >> 17) & 0x3FFF) / 16383u;
                    dequantized_uvs[1] = float( (quantized_uvs >> 3) & 0x3FFF) / 16383u;
                    dequantized_uvs[2] = float(0x7 & quantized_uvs);

                    o.uv_plus_layer = dequantized_uvs;
                }

                // let the vertex color be interpolated in any case, because the w-value indicates for the
                // fragment shader whether it should treat mixed values as UVs or vertex colors
                o.vertex_colors = vertex_colors_to_write;

                return o;
            }  

            float4 frag(v2f i) : SV_Target 
            {
                float3 uv_plus_layer = float3( float2(i.uv_plus_layer.xy), i.uv_plus_layer.z);
                float4 out_color = float4(0.0, 0.0, 0.0, 0.0);
                
                //decide based on w-value of interpolated values whether we use vertex colors or sample our array textures
                if(i.vertex_colors.w > 0.5) {
                    //https://discussions.unity.com/t/using-only-vertex-colors-result-in-faded-too-light-colors/708831
                    
                    #if defined(UNITY_COLORSPACE_GAMMA)
                        out_color = float4(i.vertex_colors.xyz, 1.0);
                    #else 
                        out_color = float4(GammaToLinearSpace(i.vertex_colors.xyz), 1.0);
                    #endif
                } else {
                    out_color = float4(UNITY_SAMPLE_TEX2DARRAY(_colorRenderTexture, uv_plus_layer).xyz, 1.0);// +float3(0.0001, 0.0001, 0.0) );
                }

                return out_color;
            }
            ENDCG
        }


        // similar implementation for the shadow mode, disregarding colors
        Pass
        {
            Cull Front
            Tags {"LightMode" = "ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR0;
            };

            StructuredBuffer<int> _Triangles;
            StructuredBuffer<uint> _Positions;
            uniform float4x4 _ObjectToWorld;
            uniform float4 _GeometryQuantBBMin;
            uniform float4 _GeometryQuantBBMax;

            v2f vert(uint vertexID: SV_VertexID, uint instanceID : SV_InstanceID)
            {
                v2f o;
                
                uint quantized_position = _Positions[vertexID];

                float3 bb_extents = _GeometryQuantBBMax - _GeometryQuantBBMin;
                float3 bb_step_size = bb_extents / float3(1023.0, 4095.0, 1023.0);

                float3 dequantized_position = float3( ((quantized_position >> 22) & 0x3FF) * bb_step_size[0], ((quantized_position >> 10) & 0xFFF) * bb_step_size[1], ((quantized_position ) & 0x3FF) * bb_step_size[2] );

                float3 pos = dequantized_position + _GeometryQuantBBMin;
                float4 wpos = mul(_ObjectToWorld, float4(pos + float3(instanceID, 0, 0), 1.0f));

                o.pos = mul(UNITY_MATRIX_VP, wpos);
                o.color = float4(pos * 0.5 + 0.5, 0.0f);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }

    }
}