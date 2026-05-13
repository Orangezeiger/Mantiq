package com.mantiq.dto.response;

public record TreeSummaryResponse(
        Integer id,
        String title,
        String description,
        int stepCount
) {}
