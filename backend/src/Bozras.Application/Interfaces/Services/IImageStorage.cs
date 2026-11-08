using Bozras.Application.Common;

namespace Bozras.Application.Interfaces.Services;

public interface IImageStorage
{
    Task<Result<string>> SaveProductImageAsync(
        Stream content, string contentType, long length, CancellationToken ct = default);
}