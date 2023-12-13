Shader "HuaJuan/Water"
{
    Properties
    {
		_MaxDepth ("MaxDepth", float) = 1000
		_UvScale ("Repect", int) = 1
		_MeshWave ("Mesh Wave Scale", float) = 1
		_Speed ("Speed", float) = 1
		[Toggle]_fogContal("FogContal", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent-100" "RenderPipeline" = "UniversalPipeline" }
        LOD 100	ZWrite On

        Pass
        {
			Tags{"LightMode" = "UniversalForward"}
			//Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile_fog
			#define FOG _fogContal

            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			            
			TEXTURE2D(_PlanarReflectionTexture); SAMPLER(sampler_PlanarReflectionTexture);
			TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);
			TEXTURE2D(_SurfaceMap); SAMPLER(sampler_SurfaceMap);
			TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
			TEXTURE2D(_WaterColor); SAMPLER(sampler_WaterColor);
			
			struct appdata
            {
                float4 vertex : POSITION;
            };

			struct v2f
            {
                float4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 additonalData : TEXCOORD4;
				float4 uv : TEXCOORD0;
				float3 posWS : TEXCOORD1;
				float4 shadowCoord : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
			#ifdef FOG
                float fogFactor : TEXCOORD5;
            #endif
            };
			struct WaveStruct
			{
				float3 position : TEXCOORD10;
				float3 normal : TEXCOORD11;
			};
	        //------------------------------			
			half3 SampleReflections(half3 normalWS, half2 screenUV, half fresnelTerm)
			{
				half3 reflection = 0;
				half2 reflectionUV = screenUV + normalWS.zx * half2(0.02, 0.15);
				reflection += SAMPLE_TEXTURE2D(_PlanarReflectionTexture, sampler_PlanarReflectionTexture, reflectionUV).rgb;//planar reflection

				return reflection * fresnelTerm;
			}

			half CalculateFresnelTerm(half3 normalWS, half3 viewDirectionWS)
			{
				return pow(1.0 - saturate(dot(normalWS, viewDirectionWS)), 4);
			}

			half2 DistortionUVs(half depth, float3 normalWS)
			{
				half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;
				return viewNormal.xz *0.022;
			}

			half4 AdditonalData(float3 postionWS)
			{
				half4 data = half4(0, 0, 0, 0);
				float3 viewPos = TransformWorldToView(postionWS);
				data.x = length(viewPos / viewPos.z);
				data.y = length(GetCameraPositionWS().xyz - postionWS);
				return data;
			}

			WaveStruct SinWave(half2 pos,float waveCountMulti, half amplitude, half angle, half wavelength)
			{
				WaveStruct waveOut;
				float time = _Time.y;
				half w = 6.28318 / wavelength;
				half wSpeed = sqrt(9.8 * w);
				angle = radians(angle);
				half2 direction = half2(sin(angle), cos(angle));
				//direction = half2(1,0);
				half dir = dot(direction, pos);	
				half calc = dir * w + time * wSpeed; // the wave calculation
				half cosCalc = cos(calc); 
				half sinCalc = sin(calc); 
				waveOut.position = 0;
				waveOut.position.y = amplitude * sinCalc*waveCountMulti;
				waveOut.normal = normalize(float3(
					-w*direction.x*amplitude*sinCalc,
					1,
					-w*direction.y*amplitude*sinCalc
					)) * waveCountMulti;
				return waveOut;
			}

			float _MeshWave;
			float _Speed;
			float _MaxDepth;
			int _UvScale;
			
            v2f vert (appdata v)
            {
                v2f o;	
				o.normal = float3(0, 1, 0);			
				o.posWS  = TransformObjectToWorld(v.vertex);
				half A = 4;
				half wavelength = 40;
				half2 windAngle = 30;
				WaveStruct wave = SinWave(o.posWS.xz, 1, A, windAngle, wavelength);
				o.normal = wave.normal.xyz;
				o.posWS += wave.position * _MeshWave;
				o.vertex = TransformWorldToHClip(o.posWS);
				o.shadowCoord = ComputeScreenPos(o.vertex);
				o.viewDir = SafeNormalize(_WorldSpaceCameraPos - o.posWS);
				float time = _Time.y * _Speed;
				// Detail UVs
				o.uv.zw = o.posWS.xz * 0.005h + time * 0.05h;
				o.uv.xy = o.posWS.xz * 0.02h - time.xx * 0.1h;
				o.additonalData = AdditonalData(o.posWS);
			#ifdef FOG
				o.fogFactor = ComputeFogFactor(o.vertex.z);
            #endif
                return o;
            }

            float4 frag (v2f IN) : SV_Target
            {	
				half4 waterColor = half4(0,0.2,0.5,0.7);
				half3 screenUV = IN.shadowCoord.xyz / IN.shadowCoord.w;
				
				// Detail waves
				half2 detailBump1 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.zw / _UvScale).xy * 8 - 1;
				half2 detailBump2 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.xy / _UvScale).xy * 8 - 1;
				half2 detailBump = (detailBump1 + detailBump2 * 0.5);
				IN.normal += half3(detailBump.x, 0, detailBump.y) * 0.3;
				IN.normal = normalize(IN.normal);
				
				// Fresnel
				half fresnelTerm = CalculateFresnelTerm(IN.normal, IN.viewDir.xyz);
				
				half3 reflection = SampleReflections(IN.normal, screenUV.xy, 1.4 * fresnelTerm);							
				
				half2 distortion = DistortionUVs(1, IN.normal);
                distortion += screenUV.xy;

				//calculate depth 
				float rawD = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV.xy);
				float CameraDephline = LinearEyeDepth(rawD, _ZBufferParams);
				float diffDepth = saturate((CameraDephline * IN.additonalData.x - IN.additonalData.y) / _MaxDepth);
				waterColor.xyz = SAMPLE_TEXTURE2D(_WaterColor, sampler_WaterColor, float2(diffDepth, 0)).xyz;

                //refraction
                half3 refraction = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortion).rgb;
                waterColor.xyz = 0.6 * waterColor.xyz + 0.05 * refraction + half3(0, 0.02, 0.1);
				waterColor.xyz += reflection;

			#ifdef FOG
                waterColor = float4(MixFog(waterColor.rgb, IN.fogFactor),1);
            #endif
				return waterColor;
            }
			
            ENDHLSL
        }
    }
}
