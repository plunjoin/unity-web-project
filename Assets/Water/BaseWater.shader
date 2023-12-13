Shader "HuaJuan/BaseWater"
{
    Properties
    {

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
            };
 
	    half3 SampleReflections(half3 normalWS, half2 screenUV, half fresnelTerm)
	    {
		half3 reflection = 0;
		half2 reflectionUV = screenUV + normalWS.zx * half2(0.02, 0.15);
		reflection += SAMPLE_TEXTURE2D(_PlanarReflectionTexture, sampler_PlanarReflectionTexture, reflectionUV).rgb;//planar reflection

		return reflection * fresnelTerm;
	    }
 
            v2f vert (appdata v)
            {
                v2f o;	
		o.normal = float3(0, 1, 0);			
		o.posWS  = TransformObjectToWorld(v.vertex);
                o.vertex = TransformWorldToHClip(o.posWS);
		o.shadowCoord = ComputeScreenPos(o.vertex);
 
		float time = _Time.y;
		// Detail UVs
		o.uv.zw = o.posWS.xz * 0.1h + time * 0.05h;
		o.uv.xy = o.posWS.xz * 0.4h - time.xx * 0.1h;

                return o;
            }

            float4 frag (v2f IN) : SV_Target
            {		
 
		half4 waterColor = half4(0,0.1,0.3,0.7);
		half3 screenUV = IN.shadowCoord.xyz / IN.shadowCoord.w;
 
		// Detail waves
		half2 detailBump1 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.zw).xy * 2 - 1;
		half2 detailBump2 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.xy).xy * 2 - 1;
		half2 detailBump = (detailBump1 + detailBump2 * 0.5);
		IN.normal += half3(detailBump.x, 0, detailBump.y) * 0.3;
		IN.normal = normalize(IN.normal);
 
		half3 reflection = SampleReflections(IN.normal, screenUV.xy, 1);
 
		waterColor.xyz += reflection;
		return waterColor;
            }
 
 
            ENDHLSL
        }
    }
}