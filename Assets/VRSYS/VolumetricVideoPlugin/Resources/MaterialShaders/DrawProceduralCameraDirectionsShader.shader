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
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR0;
                float2 uv : COLOR1;
            };

            UNITY_DECLARE_TEX2DARRAY(_colorRenderTexture);

            StructuredBuffer<int> _Triangles;
            StructuredBuffer<float3> _Positions;
            uniform float4x4 _ObjectToWorld;

            v2f vert(uint vertexID: SV_VertexID, uint instanceID : SV_InstanceID)
            {
                float3 quad_positions[6] = {
                    0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0,
                    1.0, 0.0, 0.0,
                    1.0, 0.0, 0.0,
                    0.0, 1.0, 0.0,
                    1.0, 1.0, 0.0
                };

                v2f o;
                float3 pos = quad_positions[vertexID]; //_Positions[vertexID];
                float4 wpos = mul(_ObjectToWorld, float4(pos + float3(instanceID, 0, 0), 1.0f));
                o.pos = mul(UNITY_MATRIX_VP, wpos);
                o.color = float4(pos * 0.5 + 0.5, 0.0f);
                o.uv = float2(pos.x, pos.y);
                return o;
            }  

            float4 frag(v2f i) : SV_Target
            {
                 
               // return float4(i.uv, 0.0f, 1.0f);
                
                float3 uv_plus_layer = float3(i.uv, 0);
                float4 out_color = UNITY_SAMPLE_TEX2DARRAY(_colorRenderTexture, uv_plus_layer);
                //float4 out_color = float4(i.uv, 0.0, 1.0);
                return out_color;
                //return i.color;
            }
            ENDCG
        }


        Pass
        {
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
            StructuredBuffer<float3> _Positions;
            uniform float4x4 _ObjectToWorld;

            v2f vert(uint vertexID: SV_VertexID, uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 pos = _Positions[vertexID];// _Triangles[vertexID + _StartIndex] + _BaseVertexIndex];
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