using System.Net.Http.Headers;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Services;

namespace Bozras.Infrastructure.Services;

public class SupabaseImageStorage : IImageStorage
{
    private const long MaxBytes = 5 * 1024 * 1024;

    private static readonly Dictionary<string, string> Extensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ["image/jpeg"] = ".jpg",
        ["image/png"] = ".png",
        ["image/webp"] = ".webp"
    };

    private readonly HttpClient _http;
    private readonly ILogger<SupabaseImageStorage> _logger;
    private readonly string _baseUrl;
    private readonly string _serviceKey;
    private readonly string _bucket;

    public SupabaseImageStorage(
        HttpClient http, IConfiguration configuration, ILogger<SupabaseImageStorage> logger)
    {
        _http = http;
        _logger = logger;
        _baseUrl = (configuration["Supabase:Url"] ?? throw new InvalidOperationException("Supabase:Url is not set."))
            .TrimEnd('/');
        _serviceKey = configuration["Supabase:ServiceKey"]
            ?? throw new InvalidOperationException("Supabase:ServiceKey is not set.");
        _bucket = configuration["Supabase:Bucket"] ?? "uploads";
    }

    public async Task<Result<string>> SaveProductImageAsync(
        Stream content, string contentType, long length, CancellationToken ct = default)
    {
        if (length <= 0)
            return Result<string>.Failure("Файл пустой.");

        if (length > MaxBytes)
            return Result<string>.Failure("Размер фото не должен превышать 5 МБ.");

        if (!Extensions.TryGetValue(contentType, out var extension))
            return Result<string>.Failure("Допустимые форматы: JPG, PNG, WEBP.");

        var path = $"products/{Guid.NewGuid():N}{extension}";

        using var request = new HttpRequestMessage(
            HttpMethod.Post, $"{_baseUrl}/storage/v1/object/{_bucket}/{path}");

        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceKey);
        request.Headers.Add("apikey", _serviceKey);

        var body = new StreamContent(content);
        body.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        request.Content = body;

        try
        {
            using var response = await _http.SendAsync(request, ct);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync(ct);
                _logger.LogError("Supabase upload failed: {Status} {Body}", (int)response.StatusCode, error);

                return Result<string>.Failure("Не удалось загрузить фото. Попробуйте позже.");
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Supabase upload failed.");

            return Result<string>.Failure("Не удалось загрузить фото. Попробуйте позже.");
        }

        return Result<string>.Success($"{_baseUrl}/storage/v1/object/public/{_bucket}/{path}");
    }
}