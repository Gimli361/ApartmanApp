using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Business.DTOs.Bildirim;
using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Core.Entities;
using AutoMapper;

namespace ApartmanApp.Business.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // Ariza
        CreateMap<Ariza, ArizaListDto>()
            .ForMember(dest => dest.BildirenAdSoyad,
                opt => opt.MapFrom(src => src.Bildiren != null
                    ? $"{src.Bildiren.Ad} {src.Bildiren.Soyad}"
                    : string.Empty))
            .ForMember(dest => dest.BildirenDaireNo,
                opt => opt.MapFrom(src => src.Bildiren != null
                    ? src.Bildiren.DaireNo
                    : string.Empty))
            .ForMember(dest => dest.BildirenId,
                opt => opt.MapFrom(src => src.BildirenId))
            .ForMember(dest => dest.TakipciSayisi,
                opt => opt.Ignore()); // servis katmanında set edilir

        CreateMap<Ariza, ArizaDetailDto>()
            .ForMember(dest => dest.BildirenAdSoyad,
                opt => opt.MapFrom(src => src.Bildiren != null
                    ? $"{src.Bildiren.Ad} {src.Bildiren.Soyad}"
                    : string.Empty))
            .ForMember(dest => dest.BildirenDaireNo,
                opt => opt.MapFrom(src => src.Bildiren != null
                    ? src.Bildiren.DaireNo
                    : string.Empty))
            .ForMember(dest => dest.TakipciSayisi,
                opt => opt.Ignore()) // servis katmanında set edilir
            .ForMember(dest => dest.KullaniciTakipEdiyor,
                opt => opt.Ignore()); // endpoint katmanında set edilir

        CreateMap<ArizaCreateDto, Ariza>();

        // Kullanici
        CreateMap<Kullanici, KullaniciListDto>()
            .ForMember(dest => dest.AdSoyad,
                opt => opt.MapFrom(src => $"{src.Ad} {src.Soyad}"));

        CreateMap<KullaniciCreateDto, Kullanici>();

        // Bildirim
        CreateMap<Bildirim, BildirimListDto>();

        // Aidat
        CreateMap<Aidat, AidatListDto>()
            .ForMember(dest => dest.KullaniciAdSoyad,
                opt => opt.MapFrom(src => $"{src.Kullanici.Ad} {src.Kullanici.Soyad}"))
            .ForMember(dest => dest.DaireNo,
                opt => opt.MapFrom(src => src.Kullanici.DaireNo));
    }
}
