namespace Bozras.Application.Common;

public record JwtToken(string Value, DateTime ExpiresAt);