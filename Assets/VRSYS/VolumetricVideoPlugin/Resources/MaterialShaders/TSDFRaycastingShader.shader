Shader "Custom/TSDFRaycastingShader"
{
    Properties
    {
        _TSDFVolume("Data Texture (Generated)", 3D) = "" {}
        _RenderTextureTSDFVolume("RenderTexture Texture (Generated)", 3D) = "" {}
        _colorRenderTexture("Color Render Texture (Generated)", 2DArray) = "" {}
        _packedColorTexture("Packed Color Texture (Generated)", 2D) = "" {}
        _TSDFRes("Resolution of TSDF Vol along axes", Range(8, 256) ) = 128
        //_GradientTex("Gradient Texture (Generated)", 3D) = "" {}
        //_NoiseTex("Noise Texture (Generated)", 2D) = "white" {}
        //_TFTex("Transfer Function Texture (Generated)", 2D) = "" {}
        _MinVal("Min val", Range(0.0, 1.0)) = 0.0
        _MaxVal("Max val", Range(0.0, 1.0)) = 1.0
    }


    SubShader
    {
        Tags { "Queue" = "Geometry" 
               "RenderType" = "Opaque"
               //"LightMode" = "ShadowCaster"
                //"UniversalMaterialType" = "Lit"
                //"Queue" = "AlphaTest"
                //"LightMode" = "ShadowCaster"
        }
        LOD 100
        Cull Back
        ZTest LEqual
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
             
             //#pragma multi_compile_shadowcaster
            //#pragma multi_compile __ LIGHTING_ON
            //#pragma multi_compile DEPTHWRITE_ON DEPTHWRITE_OFF
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma require 2darray

            #include "UnityCG.cginc"

            //#define CUTOUT_ON CUTOUT_PLANE || CUTOUT_BOX_INCL || CUTOUT_BOX_EXCL

            struct vert_in
            {
                float4 vertex : POSITION;
                //float4 normal : NORMAL;
                //float2 uv : TEXCOORD0;
            };

            struct frag_in
            {
                float4 vertex : SV_POSITION;
                //float2 uv : TEXCOORD0;
                float3 vertexLocal : TEXCOORD1;
                //float3 normal : NORMAL;
            };

            struct frag_out
            {
                float4 colour : SV_TARGET;
                float depth : SV_DEPTH;
            };

            sampler3D _TSDFVolume;
            //sampler3D _colorRenderTexture;
            // 
            UNITY_DECLARE_TEX2DARRAY(_colorRenderTexture);
            // 
            //sampler3D _colorRenderTexture;
            sampler2D _packedColorTexture;

            sampler3D _RenderTextureTSDFVolume;
            //sampler3D _GradientTex;
            //sampler2D _NoiseTex;
            //sampler2D _TFTex;

            float _TSDFRes;
            //float _MinVal;
            //float _MaxVal;



            float getTSDFVal(float3 pos)
            {
                return tex3Dlod(_RenderTextureTSDFVolume, float4(pos.x, pos.y, pos.z, 0) / 1.0);
                //return tex3Dlod(_TSDFVolume, float4(pos.x, pos.y, pos.z, 0) / 1.0);
            }


            // Converts local position to depth value
            float localToDepth(float3 localPos)
            {
                float4 clipPos = UnityObjectToClipPos(float4(localPos, 1.0f));

#if defined(SHADER_API_GLCORE) || defined(SHADER_API_OPENGL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                return (clipPos.z / clipPos.w) * 0.5 + 0.5;
#else
                return clipPos.z / clipPos.w;
#endif
            }



            frag_in vert_main (vert_in v)
            {
                frag_in o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = v.uv;
                o.vertexLocal = v.vertex;
                //o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float sample_sphere_dist(float3 sample_pos) {

                float3 transformed_sample_pos = sample_pos * float3(1.0, 1.0, 1.0);

                float sample_to_center_dist = length(transformed_sample_pos);// - float3(0.5, 0.5, 0.5));
                
                float sphere_radius = 0.5;

                return sphere_radius - sample_to_center_dist;
            }

            // Direct Volume Rendering
            frag_out frag_dvr (frag_in i)
            {
                #define HALF_VOXEL_SIZE (1.0f / (_TSDFRes*1.732f*3.0f) )
                #define NUM_STEPS ( (1.0f / HALF_VOXEL_SIZE)/8.0)


                const float stepSize = 1.0/*greatest distance in box*/ / NUM_STEPS;//NUM_STEPS;

                float3 rayStartPos = i.vertexLocal + 0.5; //float3(0.5f, 0.5f, 0.5f);

                //float3 lightDir = normalize(ObjSpaceViewDir(float4(float3(0.0f, 0.0f, 0.0f), 0.0f)));
                //float3 rayDir = ObjSpaceViewDir(float4(i.vertexLocal * 0.5 + 0.5, 0.0f));
                float3 rayDir = -ObjSpaceViewDir(float4(i.vertexLocal, 1.0));
                rayDir = normalize(rayDir);

                // Create a small random offset in order to remove artifacts
                rayStartPos = rayStartPos + ( rayDir / _TSDFRes);// * tex2D(_NoiseTex, float2(i.uv.x, i.uv.y)).r;

                float4 col = float4(0.0f, 0.0f, 0.0f, 0.0f);
                uint iDepth = 0;

                float max_encountered_dist = 0.0;

                int num_samples_taken = 0;

                bool found_valid_surface = false;
                float3 final_isosurface_pos = float3(0.0, 0.0, 0.0);
                bool had_first_sample = false;
                float last_dist_sample = 0.0f;
                float curr_dist_sample = 0.0f;

                float3 lastPos = float3(0.0, 0.0, 0.0);
                float3 currPos = rayStartPos + rayDir * 0.0001;// float3(0.0, 0.0, 0.0);

                float last_unquantized_distance_sample = 0.0;
                for (uint iStep = 0; iStep < NUM_STEPS; ++iStep)
                {
                    //last_unquantized_distance_sample = 8 * abs((curr_dist_sample - 0.5) * 2.0);

                    const float t = iStep * stepSize;
                    currPos +=  rayDir * stepSize;
     
                    if (currPos.x < 0.0f || currPos.x >= 1.0f || currPos.y < 0.0f || currPos.y > 1.0f || currPos.z < 0.0f || currPos.z > 1.0f) // TODO: avoid branch?
                        break;

                    curr_dist_sample = getTSDFVal(currPos);
                    


                    //const float curr_dist_sample = sample_sphere_dist(currPos);


                    if(!had_first_sample) {
                        had_first_sample = true;

                    } else {

                        if(sign(last_dist_sample - 0.5) != sign(curr_dist_sample - 0.5) ) {
                            found_valid_surface = true;
                            final_isosurface_pos = currPos;
                            break;
                        }
                        
                            
                        
                    }

                   
                    lastPos = currPos;
                    last_dist_sample = curr_dist_sample;
                    // Calculate gradient (needed for lighting and 2D transfer functions)
                    




                    ++num_samples_taken;
                }

                // Write fragment output
                frag_out output;
                output.colour = col;
		        output.colour = float4(1.0, 1.0, 0.0, 1.0);
		        output.colour = float4(i.vertexLocal * 0.5 + 0.5, 1.0);


                output.colour = float4(max_encountered_dist, 0.0, 0.0, 1.0);

                if (found_valid_surface) {
                    for (int bin_search_it = 0; bin_search_it < 6; ++bin_search_it) {
                        float3 midPos = 0.5f * (lastPos + currPos);

                        const float mid_dist_sample = getTSDFVal(midPos);
                        
                        if (sign(last_dist_sample - 0.5) != sign(mid_dist_sample - 0.5)) {
                            curr_dist_sample = mid_dist_sample;
                            currPos = midPos;
                        }
                        else {
                            last_dist_sample = mid_dist_sample;
                            lastPos = midPos;
                        }
                    }

                    final_isosurface_pos = 0.5f * (lastPos + currPos);
                }

                if(found_valid_surface) {
                    output.colour = float4(0.5, 0.5, 0.5, 1.0);

                    float eps_dist = HALF_VOXEL_SIZE;
                    float x_grad = getTSDFVal( float3(final_isosurface_pos.x + eps_dist, final_isosurface_pos.y, final_isosurface_pos.z) ) - getTSDFVal( float3(final_isosurface_pos.x - eps_dist, final_isosurface_pos.y, final_isosurface_pos.z) );
                    float y_grad = getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y + eps_dist, final_isosurface_pos.z) ) - getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y - eps_dist,  final_isosurface_pos.z) );
                    float z_grad = getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y, final_isosurface_pos.z + eps_dist) ) - getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y, final_isosurface_pos.z - eps_dist ) );

                    float3 normal = -normalize(float3(x_grad, y_grad, z_grad));


                    float3 vs_normal = normalize(mul(UNITY_MATRIX_IT_MV, float4(normal, 0.0)).xyz);

  
                    output.colour = float4(vs_normal * 0.5 + 0.5, 1.0); //+ 0.5



                    output.depth = localToDepth(final_isosurface_pos - float3(0.5f, 0.5f, 0.5f));
                } else {
                    output.colour = float4(num_samples_taken/100.0, 0.0, 0.0, 1.0);
                    output.depth = 0;
                }


             
                return output;
            }

            frag_in vert(vert_in v)
            {
                return vert_main(v);
            }

            frag_out frag(frag_in i)
            {
                return frag_dvr(i);
            }
            ENDCG
        }
    }




        SubShader
    {
        Tags { "Queue" = "Geometry" 
               "RenderType" = "Opaque"
               //"LightMode" = "ShadowCaster"
                //"UniversalMaterialType" = "Lit"
                //"Queue" = "AlphaTest"
                //"LightMode" = "ShadowCaster"
        }
        LOD 100
        Cull Back
        ZTest LEqual
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
             
             //#pragma multi_compile_shadowcaster
            //#pragma multi_compile __ LIGHTING_ON
            //#pragma multi_compile DEPTHWRITE_ON DEPTHWRITE_OFF
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //#define CUTOUT_ON CUTOUT_PLANE || CUTOUT_BOX_INCL || CUTOUT_BOX_EXCL

            struct vert_in
            {
                float4 vertex : POSITION;
                //float4 normal : NORMAL;
                //float2 uv : TEXCOORD0;
            };

            struct frag_in
            {
                float4 vertex : SV_POSITION;
                //float2 uv : TEXCOORD0;
                float3 vertexLocal : TEXCOORD1;
                //float3 normal : NORMAL;
            };

            struct frag_out
            {
                float4 colour : SV_TARGET;
                float depth : SV_DEPTH;
            };

            sampler3D _TSDFVolume;
            sampler2D _colorTexture;

            sampler3D _RenderTextureTSDFVolume;
            //sampler3D _GradientTex;
            //sampler2D _NoiseTex;
            //sampler2D _TFTex;

            float _TSDFRes;
            //float _MinVal;
            //float _MaxVal;



            float getTSDFVal(float3 pos)
            {
                return tex3Dlod(_RenderTextureTSDFVolume, float4(pos.x, pos.y, pos.z, 0) / 1.0);
                //return tex3Dlod(_TSDFVolume, float4(pos.x, pos.y, pos.z, 0) / 1.0);
            }


            // Converts local position to depth value
            float localToDepth(float3 localPos)
            {
                float4 clipPos = UnityObjectToClipPos(float4(localPos, 1.0f));

#if defined(SHADER_API_GLCORE) || defined(SHADER_API_OPENGL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                return (clipPos.z / clipPos.w) * 0.5 + 0.5;
#else
                return clipPos.z / clipPos.w;
#endif
            }



            frag_in vert_main (vert_in v)
            {
                frag_in o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = v.uv;
                o.vertexLocal = v.vertex;
                //o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float sample_sphere_dist(float3 sample_pos) {

                float3 transformed_sample_pos = sample_pos * float3(1.0, 1.0, 1.0);

                float sample_to_center_dist = length(transformed_sample_pos);// - float3(0.5, 0.5, 0.5));
                
                float sphere_radius = 0.5;

                return sphere_radius - sample_to_center_dist;
            }

            // Direct Volume Rendering
            frag_out frag_dvr (frag_in i)
            {
                #define HALF_VOXEL_SIZE (1.0f / (_TSDFRes*1.732f*3.0f) )
                #define NUM_STEPS ( (1.0f / HALF_VOXEL_SIZE)/8.0)


                const float stepSize = 1.0/*greatest distance in box*/ / NUM_STEPS;//NUM_STEPS;

                float3 rayStartPos = i.vertexLocal + 0.5; //float3(0.5f, 0.5f, 0.5f);

                //float3 lightDir = normalize(ObjSpaceViewDir(float4(float3(0.0f, 0.0f, 0.0f), 0.0f)));
                //float3 rayDir = ObjSpaceViewDir(float4(i.vertexLocal * 0.5 + 0.5, 0.0f));
                float3 rayDir = -ObjSpaceViewDir(float4(i.vertexLocal, 1.0));
                rayDir = normalize(rayDir);

                // Create a small random offset in order to remove artifacts
                rayStartPos = rayStartPos + ( rayDir / _TSDFRes);// * tex2D(_NoiseTex, float2(i.uv.x, i.uv.y)).r;

                float4 col = float4(0.0f, 0.0f, 0.0f, 0.0f);
                uint iDepth = 0;

                float max_encountered_dist = 0.0;

                int num_samples_taken = 0;

                bool found_valid_surface = false;
                float3 final_isosurface_pos = float3(0.0, 0.0, 0.0);
                bool had_first_sample = false;
                float last_dist_sample = 0.0f;
                float curr_dist_sample = 0.0f;

                float3 lastPos = float3(0.0, 0.0, 0.0);
                float3 currPos = rayStartPos + rayDir * 0.0001;// float3(0.0, 0.0, 0.0);

                float last_unquantized_distance_sample = 0.0;
                for (uint iStep = 0; iStep < NUM_STEPS; ++iStep)
                {
                    //last_unquantized_distance_sample = 8 * abs((curr_dist_sample - 0.5) * 2.0);

                    const float t = iStep * stepSize;
                    currPos +=  rayDir * stepSize;
     
                    if (currPos.x < 0.0f || currPos.x >= 1.0f || currPos.y < 0.0f || currPos.y > 1.0f || currPos.z < 0.0f || currPos.z > 1.0f) // TODO: avoid branch?
                        break;

                    curr_dist_sample = getTSDFVal(currPos);
                    


                    //const float curr_dist_sample = sample_sphere_dist(currPos);


                    if(!had_first_sample) {
                        had_first_sample = true;

                    } else {

                        if(sign(last_dist_sample - 0.5) != sign(curr_dist_sample - 0.5) ) {
                            found_valid_surface = true;
                            final_isosurface_pos = currPos;
                            break;
                        }
                        
                            
                        
                    }

                   
                    lastPos = currPos;
                    last_dist_sample = curr_dist_sample;
                    // Calculate gradient (needed for lighting and 2D transfer functions)
                    




                    ++num_samples_taken;
                }

                // Write fragment output
                frag_out output;
                output.colour = col;
		        output.colour = float4(1.0, 1.0, 0.0, 1.0);
		        output.colour = float4(i.vertexLocal * 0.5 + 0.5, 1.0);


                output.colour = float4(max_encountered_dist, 0.0, 0.0, 1.0);

                if (found_valid_surface) {
                    for (int bin_search_it = 0; bin_search_it < 6; ++bin_search_it) {
                        float3 midPos = 0.5f * (lastPos + currPos);

                        const float mid_dist_sample = getTSDFVal(midPos);
                        
                        if (sign(last_dist_sample - 0.5) != sign(mid_dist_sample - 0.5)) {
                            curr_dist_sample = mid_dist_sample;
                            currPos = midPos;
                        }
                        else {
                            last_dist_sample = mid_dist_sample;
                            lastPos = midPos;
                        }
                    }

                    final_isosurface_pos = 0.5f * (lastPos + currPos);
                }

                if(found_valid_surface) {
                    output.colour = float4(0.5, 0.5, 0.5, 1.0);

                    float eps_dist = HALF_VOXEL_SIZE;
                    float x_grad = getTSDFVal( float3(final_isosurface_pos.x + eps_dist, final_isosurface_pos.y, final_isosurface_pos.z) ) - getTSDFVal( float3(final_isosurface_pos.x - eps_dist, final_isosurface_pos.y, final_isosurface_pos.z) );
                    float y_grad = getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y + eps_dist, final_isosurface_pos.z) ) - getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y - eps_dist,  final_isosurface_pos.z) );
                    float z_grad = getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y, final_isosurface_pos.z + eps_dist) ) - getTSDFVal( float3(final_isosurface_pos.x, final_isosurface_pos.y, final_isosurface_pos.z - eps_dist ) );

                    float3 normal = -normalize(float3(x_grad, y_grad, z_grad));


                    float3 vs_normal = normalize(mul(UNITY_MATRIX_IT_MV, float4(normal, 0.0)).xyz);

  
                    output.colour = float4(vs_normal * 0.5 + 0.5, 1.0); //+ 0.5



                    output.depth = localToDepth(final_isosurface_pos - float3(0.5f, 0.5f, 0.5f));
                } else {
                    output.colour = float4(num_samples_taken/100.0, 0.0, 0.0, 1.0);
                    output.depth = 0;
                }


             
                return output;
            }

            frag_in vert(vert_in v)
            {
                return vert_main(v);
            }

            frag_out frag(frag_in i)
            {
                return frag_dvr(i);
            }
            ENDCG
        }
    }


}
