//
//  Shader.fsh
//  TestVR
//
//  Created by Andy Qua on 19/09/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//
precision mediump float;

varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform vec2 LensCenter;
uniform vec2 ScreenCenter;
uniform vec2 Scale;
uniform vec2 ScaleIn;
uniform vec4 HmdWarpParam;

vec2 HmdWarp(vec2 in01)
{
    vec2 theta = (in01 - LensCenter) * ScaleIn;
    float rSq = theta.x * theta.x + theta.y * theta.y;
    vec2  theta1 = theta * (HmdWarpParam.x + HmdWarpParam.y * rSq + HmdWarpParam.z * rSq * rSq + HmdWarpParam.w * rSq * rSq * rSq);
    return ScreenCenter + Scale * theta1;
}
void main()
{
    vec2 tc = HmdWarp(textureCoordinate);
    if (!all(equal(clamp(tc, ScreenCenter-vec2(0.5,0.5), ScreenCenter+vec2(0.5,0.5)), tc)))
        gl_FragColor = vec4(0);
    else
        gl_FragColor = texture2D(inputImageTexture, tc);
}