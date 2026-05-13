package com.mantiq.dto.response;

import java.math.BigDecimal;
import java.util.List;

public record TaskResponse(
        Integer id,
        String question,
        String type,
        List<OptionResponse> options,
        BigDecimal numberMin,
        BigDecimal numberMax,
        BigDecimal numberCorrect
) {}
