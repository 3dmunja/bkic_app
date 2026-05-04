const String baseUrl = 'https://bkicsaff.dk/wp-json/bkicsaff/v1';

const String loginEndpoint = '$baseUrl/auth/login';
const String logoutEndpoint = '$baseUrl/auth/logout';
const String registerEndpoint = '$baseUrl/auth/register';
const String forgotPasswordEndpoint = '$baseUrl/auth/forgot-password';

const String meEndpoint = '$baseUrl/me';
const String pageEndpoint = '$baseUrl/pages';
const String contactEndpoint = '$baseUrl/contact';
const String membershipEndpoint = '$baseUrl/me/membership';

// Profil
const String updateProfileEndpoint = '$baseUrl/me/update-profile';

const String homeNewsEndpoint = '$baseUrl/home/news';
const String homeEventsEndpoint = '$baseUrl/home/events';

const String eventRegisterEndpoint = '$baseUrl/events/register';
const String eventUnregisterEndpoint = '$baseUrl/events/unregister';
const String eventStatusEndpoint = '$baseUrl/events/status';

const String adminEventsEndpoint = '$baseUrl/admin/events';
const String adminEventSaveEndpoint = '$baseUrl/admin/events/save';
const String adminEventDeleteEndpoint = '$baseUrl/admin/events/delete';
const String adminEventUploadImageEndpoint =
    '$baseUrl/admin/events/upload-image';

const String adminMemberMapEndpoint = '$baseUrl/admin/member-map';

const String adminNewsEndpoint = '$baseUrl/admin/vijesti';
const String adminNewsSaveEndpoint = '$baseUrl/admin/vijesti/save';
const String adminNewsDeleteEndpoint = '$baseUrl/admin/vijesti/delete';

const String registerDeviceEndpoint = '$baseUrl/devices/register';
const String unregisterDeviceEndpoint = '$baseUrl/devices/unregister';

const String tokenStorageKey = 'token';
const String fcmTokenStorageKey = 'fcm_device_token';
const String lastRegisteredDeviceTokenKey = 'last_registered_device_token';