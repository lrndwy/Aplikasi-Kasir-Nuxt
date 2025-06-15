<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Manajemen Pelanggan
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAdminOrManagerRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isCustomerFormOpen" @update:open="isCustomerFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewCustomer">Tambah Pelanggan Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Pelanggan" : "Tambah Pelanggan Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing
                    ? "Perbarui detail pelanggan."
                    : "Tambahkan pelanggan baru ke daftar."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveCustomer" class="space-y-4 py-4">
              <div>
                <Label for="customerName" class="mb-2">Nama Pelanggan</Label>
                <Input
                  id="customerName"
                  v-model="customerForm.name"
                  type="text"
                  placeholder="Nama Pelanggan"
                  required
                />
              </div>
              <div>
                <Label for="customerEmail" class="mb-2">Email</Label>
                <Input
                  id="customerEmail"
                  v-model="customerForm.email"
                  type="email"
                  placeholder="email@example.com"
                />
              </div>
              <div>
                <Label for="customerPhone" class="mb-2">Telepon</Label>
                <Input
                  id="customerPhone"
                  v-model="customerForm.phone"
                  type="text"
                  placeholder="Nomor Telepon"
                />
              </div>
              <div>
                <Label for="customerAddress" class="mb-2">Alamat</Label>
                <Textarea
                  id="customerAddress"
                  v-model="customerForm.address"
                  placeholder="Alamat Lengkap"
                />
              </div>
              <div v-if="errorMessage" class="text-red-500 text-sm mt-4">
                {{ errorMessage }}
              </div>
              <div v-if="successMessage" class="text-green-500 text-sm mt-4">
                {{ successMessage }}
              </div>
              <DialogFooter>
                <Button type="submit" :disabled="loading">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Pelanggan" : "Tambah Pelanggan"
                  }}</span>
                </Button>
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    >Batal</Button
                  >
                </DialogClose>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Pelanggan -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Daftar Pelanggan
        </h2>
        <div class="overflow-x-auto">
          <Table class="min-w-full">
            <TableHeader>
              <TableRow>
                <TableHead class="min-w-[150px]">Nama</TableHead>
                <TableHead class="min-w-[120px]">Email</TableHead>
                <TableHead class="min-w-[100px]">Telepon</TableHead>
                <TableHead class="min-w-[150px]">Alamat</TableHead>
                <TableHead class="min-w-[150px]">Dibuat Pada</TableHead>
                <TableHead class="min-w-[150px]">Diperbarui Pada</TableHead>
                <TableHead class="min-w-[150px]">Aksi</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-for="customer in customers" :key="customer.id">
                <TableCell>{{ customer.name }}</TableCell>
                <TableCell>{{ customer.email || "-" }}</TableCell>
                <TableCell>{{ customer.phone || "-" }}</TableCell>
                <TableCell>{{ customer.address || "-" }}</TableCell>
                <TableCell>{{ formatDate(customer.created_at) }}</TableCell>
                <TableCell>{{ formatDate(customer.updated_at) }}</TableCell>
                <TableCell>
                  <Button
                    variant="outline"
                    size="sm"
                    @click="editCustomer(customer)"
                    class="mr-2"
                    >Edit</Button
                  >
                  <Button
                    variant="destructive"
                    size="sm"
                    @click="confirmDeleteCustomer(customer.id)"
                    >Hapus</Button
                  >
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </div>
        <div
          v-if="customers.length === 0 && !loading"
          class="text-center text-gray-500 dark:text-gray-400 mt-4"
        >
          Tidak ada pelanggan ditemukan.
        </div>
      </div>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Pelanggan</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus pelanggan ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteCustomerConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Customers - Aplikasi Kasir'
})
import { ref, onMounted } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { watch } from "vue";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";

interface Customer {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const customers = ref<Customer[]>([]);
const customerForm = ref({
  id: "",
  name: "",
  email: "",
  phone: "",
  address: "",
});
const pageLoading = ref(true); // New ref for overall page loading
const isEditing = ref(false);
const loading = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const hasAdminOrManagerRole = ref(false);
const isCustomerFormOpen = ref(false); // Controls the add/edit customer dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const customerToDeleteId = ref<string | null>(null); // Stores the ID of the customer to be deleted

const fetchCustomers = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("customers")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    customers.value = data as Customer[];
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminOrManagerRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    console.error("Error fetching user role:", error.message);
    hasAdminOrManagerRole.value = false;
    return;
  }
  // Authenticated users can create, Admin/Manager can manage (view, edit, delete)
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const saveCustomer = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const customerData = {
      name: customerForm.value.name,
      email: customerForm.value.email || null,
      phone: customerForm.value.phone || null,
      address: customerForm.value.address || null,
    };

    if (isEditing.value) {
      const { error } = await supabase
        .from("customers")
        .update({ ...customerData, updated_at: new Date().toISOString() })
        .eq("id", customerForm.value.id);
      if (error) throw error;
      successMessage.value = "Pelanggan berhasil diperbarui!";
    } else {
      const { error } = await supabase.from("customers").insert(customerData);
      if (error) throw error;
      successMessage.value = "Pelanggan berhasil ditambahkan!";
    }
    resetForm();
    await fetchCustomers();
    isCustomerFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const addNewCustomer = () => {
  resetForm();
  isCustomerFormOpen.value = true;
};

const editCustomer = (customer: Customer) => {
  isEditing.value = true;
  customerForm.value = { ...customer };
  errorMessage.value = "";
  successMessage.value = "";
  isCustomerFormOpen.value = true; // Open the dialog for editing
};

const cancelEdit = () => {
  resetForm();
  isCustomerFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteCustomer = (id: string) => {
  customerToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteCustomerConfirmed = async () => {
  if (!customerToDeleteId.value) return;

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const { error } = await supabase
      .from("customers")
      .delete()
      .eq("id", customerToDeleteId.value);
    if (error) throw error;
    successMessage.value = "Pelanggan berhasil dihapus!";
    await fetchCustomers();
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    customerToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  customerForm.value = {
    id: "",
    name: "",
    email: "",
    phone: "",
    address: "",
  };
};

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCustomers();
    }
  } finally {
    pageLoading.value = false; // End loading
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    // No need to set pageLoading here, as this watch is for reactive changes after initial load
    // The initial load is handled by onMounted
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCustomers();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    customers.value = [];
  }
});
</script>

<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #3b82f6; /* Blue-500 */
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
