Shader "HuaJuan/BaseWaterFresnel"
{
    Properties
    {
		_WaterColor ("Water Color", Color) = (1,1,1,1)
		_GlobalScale ("Global Scale", float) = 1
		_WaveScale ("Wave Scale", Vector) = (1,1,1,1)
		_WaveSpeed ("Wave Speed", Vector) = (1,1,1,1)
		_ReflectColor ("Reflect Color", Color) = (1,1,1,1)
		_Reflect ("Reflect", Range(0,1)) = 0.5
		_NormalScale ("Normal Scale", Range(0,1)) = 0.5
		[Toggle]
		_fogContal("FogContal", float) = 1
		[NoScaleOffset]
		_EmissionTex ("Emission", 2D) = "black" {}
		_EmSize ("Emission Size", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent-100" "RenderPipeline" = "UniversalPipeline" }
		LOD 100
		ZWrite On

		Pass
        {
			Tags{"LightMode" = "UniversalForward"}
			Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile_fog
			#define FOG _fogContal

            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
			TEXTURE2D(_PlanarReflectionTexture); SAMPLER(sampler_PlanarReflectionTexture);
			TEXTURE2D(_SurfaceMap); SAMPLER(sampler_SurfaceMap);
			
			struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : POSITION;
				half3 	normal : NORMAL;
				float4 uv : TEXCOORD0;
				float3	posWS : TEXCOORD1;
				float4	shadowCoord : TEXCOORD2;
				float3 	viewDir : TEXCOORD3;
			#ifdef FOG
                float fogFactor : TEXCOORD4;
            #endif
            };
				
			half3 SampleReflections(half3 normalWS, half2 screenUV, half fresnelTerm)
			{
				half3 reflection = 0;
				half2 reflectionUV = screenUV + normalWS.zx * half2(0.02, 0.15);
				reflection += SAMPLE_TEXTURE2D(_PlanarReflectionTexture, sampler_PlanarReflectionTexture, reflectionUV).rgb;//planar reflection

				return reflection * fresnelTerm;
			}
			half CalculateFresnelTerm(half3 normalWS, half3 viewDirectionWS)
			{
				return pow(1.0 - saturate(dot(normalWS, viewDirectionWS)), 10);
			}

			float4 _WaterColor;
			float _GlobalScale;
			float4 _WaveScale;
			float4 _WaveSpeed;
			float4 _ReflectColor;
			float _Reflect;
			float _NormalScale;

			sampler2D _EmissionTex;
			float _EmSize;
			
            v2f vert (appdata v)
            {
                v2f o;	
				o.normal = float3(0, 1, 0);			
				o.posWS  = TransformObjectToWorld(v.vertex);
                o.vertex = TransformWorldToHClip(o.posWS);
				o.shadowCoord = ComputeScreenPos(o.vertex);
				o.viewDir = SafeNormalize(_WorldSpaceCameraPos - o.posWS);
				float time = _Time.y;
				// Detail UVs
				o.uv.xy = o.posWS.xz * _WaveScale.xy * _GlobalScale + time * _WaveSpeed.xy;
				o.uv.zw = o.posWS.xz * _WaveScale.zw * _GlobalScale + time * _WaveSpeed.zw;
			#ifdef FOG
				o.fogFactor = ComputeFogFactor(o.vertex.z);
            #endif
				
                return o;
            }

            float4 frag (v2f IN) : SV_Target
            {		
				
				half4 waterColor = _WaterColor;
				waterColor.xyz *= 1 - _Reflect;
				half3 screenUV = IN.shadowCoord.xyz / IN.shadowCoord.w;				
				// Detail waves
				half2 detailBump1 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.zw).xy * 2 - 1;
				half2 detailBump2 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.xy).xy * 2 - 1;
				half2 detailBump = (detailBump1 + detailBump2 * 0.5);
				IN.normal += half3(detailBump.x, 0, detailBump.y) * _NormalScale;
				IN.normal = normalize(IN.normal);
				
				// Fresnel
				half fresnelTerm = CalculateFresnelTerm(IN.normal, IN.viewDir.xyz);				
				//float reverseFresnelTerm = 1 - fresnelTerm;
				
				//half3 reflection = SampleReflections(IN.normal, screenUV.xy, fresnelTerm) * _ReflectColor;
				//half3 reflection = SampleReflections(IN.normal, screenUV.xy, reverseFresnelTerm) * _ReflectColor;
				half3 reflection = SampleReflections(IN.normal, screenUV.xy, 1) * _ReflectColor;
							
				waterColor.xyz += reflection * _Reflect;
				waterColor.xyz += tex2D(_EmissionTex, IN.posWS.xz * _EmSize).xyz;

			#ifdef FOG
                waterColor = float4(MixFog(waterColor.rgb, IN.fogFactor),1);
            #endif
				//return fresnelTerm.xxxx;
				return waterColor;
            }	
            ENDHLSL
        }
    }
}