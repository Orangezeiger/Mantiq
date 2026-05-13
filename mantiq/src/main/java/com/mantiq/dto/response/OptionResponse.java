package com.mantiq.dto.response;

public record OptionResponse(
        Integer id,
        String text,
        boolean correct,
        Integer position,
        Integer matchGroup
) {}
