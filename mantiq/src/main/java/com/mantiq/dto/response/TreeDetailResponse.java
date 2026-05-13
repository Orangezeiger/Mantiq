package com.mantiq.dto.response;

import java.util.List;

public record TreeDetailResponse(
        Integer id,
        String title,
        String description,
        List<StepResponse> steps
) {}
