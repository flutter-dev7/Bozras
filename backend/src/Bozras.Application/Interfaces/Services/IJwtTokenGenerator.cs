using Bozras.Application.Common;
using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Services;

public interface IJwtTokenGenerator
{
    JwtToken Generate(User user);
}