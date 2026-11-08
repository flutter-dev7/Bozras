using Bozras.Domain.Enums;

namespace Bozras.Application.Common;

public record CurrentUser(Guid Id, UserRole Role);